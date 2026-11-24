const DEFAULT_API_BASE_URL = "http://127.0.0.1:8001/api";
const storedApiBaseUrl = localStorage.getItem("coach_api_base_url");
const initialApiBaseUrl =
  !storedApiBaseUrl || storedApiBaseUrl === "http://127.0.0.1:8000/api"
    ? DEFAULT_API_BASE_URL
    : storedApiBaseUrl;

if (storedApiBaseUrl !== initialApiBaseUrl) {
  localStorage.setItem("coach_api_base_url", initialApiBaseUrl);
}

const EMPTY_DASHBOARD = {
  total_athletes: 0,
  active_athletes: 0,
  pending_reviews: 0,
  average_consistency: 0,
  athlete_rankings: [],
};

function emptyAdminUserForm() {
  return {
    name: "",
    email: "",
    role: "coach",
    password: "",
    password_confirmation: "",
    height: "",
    weight: "",
    age: "",
    training_level: "Beginner",
  };
}

function emptyAdminProgramForm() {
  return {
    title: "",
    name: "",
    level: "Beginner",
    day_number: "",
  };
}

function emptyAdminProgramExerciseForm() {
  return {
    name: "",
    type: "training",
    video_url: "",
    sets: "3",
    reps: "10",
    duration: "",
    rest_seconds: "30",
  };
}

function emptyAdminVideoForm() {
  return {
    workout_exercise_id: "",
    video_url: "",
  };
}

const state = {
  view: "dashboard",
  authMode: "login",
  apiBaseUrl: initialApiBaseUrl,
  token: localStorage.getItem("coach_token") || "",
  coachName: localStorage.getItem("coach_name") || "Coach",
  userRole: localStorage.getItem("coach_role") || "",
  loading: false,
  error: "",
  dashboard: null,
  athletes: [],
  recordings: [],
  adminUsers: [],
  adminPrograms: [],
  adminVideos: [],
  adminAthleteVideos: [],
  selectedAthleteId: null,
  selectedRecordingId: null,
  selectedProgramId: null,
  selectedVideoProgramKey: null,
  search: "",
  recordingSearch: "",
  recordingStatusFilter: "all",
  adminSearch: "",
  adminRoleFilter: "all",
  adminProgramSearch: "",
  adminVideoSearch: "",
  adminAthleteVideoSearch: "",
  adminAthleteVideoStatusFilter: "all",
  editingAdminUserId: null,
  adminUserForm: emptyAdminUserForm(),
  editingAdminProgramId: null,
  adminProgramForm: emptyAdminProgramForm(),
  editingProgramExerciseId: null,
  adminProgramExerciseForm: emptyAdminProgramExerciseForm(),
  editingAdminVideoId: null,
  adminVideoForm: emptyAdminVideoForm(),
  adminVideoUploadFile: null,
  reviewDraft: {
    status: "approved",
    score: 80,
    feedback: "",
  },
};

const requestedView = new URLSearchParams(window.location.search).get("view");
if (requestedView && isViewAllowedForRole(requestedView, state.userRole)) {
  state.view = requestedView;
}

if (state.token && !["coach", "admin"].includes(state.userRole)) {
  state.token = "";
  state.coachName = "Coach";
  state.userRole = "";
  localStorage.removeItem("coach_token");
  localStorage.removeItem("coach_name");
  localStorage.removeItem("coach_role");
}

const app = document.querySelector("#app");

function setState(patch) {
  Object.assign(state, patch);
  render();
}

function normalizeList(data) {
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.data)) return data.data;
  if (Array.isArray(data?.data?.data)) return data.data.data;
  return [];
}

function clampPercent(value) {
  const number = Number(value || 0);
  if (!Number.isFinite(number)) return 0;
  return Math.min(100, Math.max(0, Math.round(number)));
}

function rankingScoreForAthlete(athlete) {
  const consistency = clampPercent(athlete.consistency_progress);
  const coachScore = clampPercent(
    athlete.coach_score ?? athlete.performance_progress,
  );

  return clampPercent(athlete.ranking_score ?? (consistency + coachScore) / 2);
}

function athleteRankings(athletes) {
  return athletes
    .map((athlete) => ({
      id: athlete.id,
      name: athlete.name || "-",
      email: athlete.email || "",
      training_level: athlete.training_level || "-",
      consistency_progress: clampPercent(athlete.consistency_progress),
      coach_score: clampPercent(
        athlete.coach_score ?? athlete.performance_progress,
      ),
      coach_review_count: Number(athlete.coach_review_count || 0),
      completed_days: Number(athlete.completed_days || 0),
      total_program_days: Number(athlete.total_program_days || 0),
      ranking_score: rankingScoreForAthlete(athlete),
    }))
    .sort((left, right) => {
      if (right.ranking_score !== left.ranking_score) {
        return right.ranking_score - left.ranking_score;
      }
      if (right.consistency_progress !== left.consistency_progress) {
        return right.consistency_progress - left.consistency_progress;
      }
      if (right.coach_score !== left.coach_score) {
        return right.coach_score - left.coach_score;
      }
      return String(left.name).localeCompare(String(right.name));
    })
    .map((athlete, index) => ({ ...athlete, rank: index + 1 }));
}

function dashboardFromData(athletes, recordings) {
  const totalAthletes = athletes.length;
  const pendingReviews = recordings.filter((item) => item.status === "pending").length;
  const activeAthletes = athletes.filter((athlete) => athlete.last_activity_at).length;
  const averageConsistency = totalAthletes
    ? Math.round(
        athletes.reduce(
          (sum, athlete) => sum + Number(athlete.consistency_progress || 0),
          0,
        ) / totalAthletes,
      )
    : 0;

  return {
    total_athletes: totalAthletes,
    active_athletes: activeAthletes,
    pending_reviews: pendingReviews,
    average_consistency: averageConsistency,
    athlete_rankings: athleteRankings(athletes),
  };
}

async function request(path, options = {}) {
  const headers = {
    Accept: "application/json",
    ...(options.body instanceof FormData
      ? {}
      : { "Content-Type": "application/json" }),
    ...(state.token ? { Authorization: `Bearer ${state.token}` } : {}),
    ...(options.headers || {}),
  };

  const response = await fetch(`${state.apiBaseUrl}${path}`, {
    ...options,
    headers,
  });

  const text = await response.text();
  const body = text ? JSON.parse(text) : {};

  if (!response.ok || body.success === false) {
    if (response.status === 401 && state.token) {
      state.token = "";
      state.coachName = "Coach";
      state.userRole = "";
      localStorage.removeItem("coach_token");
      localStorage.removeItem("coach_name");
      localStorage.removeItem("coach_role");
    }

    const validationMessage = body.errors
      ? Object.values(body.errors).flat().find(Boolean)
      : null;
    throw new Error(validationMessage || body.message || `Request gagal (${response.status})`);
  }

  return body;
}

async function loadCoachData() {
  state.loading = true;
  state.error = "";
  render();

  try {
    if (state.userRole === "admin") {
      const [adminUsers, adminPrograms, adminVideos, adminAthleteVideos] = await Promise.all([
        request("/admin/users"),
        request("/admin/programs"),
        request("/admin/videos"),
        request("/admin/athlete-videos?status=all"),
      ]);

      state.adminUsers = normalizeList(adminUsers);
      state.adminPrograms = normalizeList(adminPrograms);
      state.adminVideos = normalizeList(adminVideos);
      state.adminAthleteVideos = normalizeList(adminAthleteVideos);
      state.dashboard = null;
      state.athletes = [];
      state.recordings = [];
      state.view = [
        "dashboard",
        "admin-users",
        "admin-programs",
        "admin-videos",
        "admin-athlete-videos",
        "settings",
      ].includes(state.view)
        ? state.view
        : "dashboard";
    } else {
      const [dashboard, athletes, recordings] = await Promise.all([
        request("/coach/dashboard"),
        request("/coach/athletes"),
        request("/coach/recordings?status=all"),
      ]);

      state.dashboard = dashboard.data || dashboard;
      state.athletes = normalizeList(athletes);
      state.recordings = normalizeList(recordings);
      state.adminUsers = [];
      state.adminPrograms = [];
      state.adminVideos = [];
      state.adminAthleteVideos = [];
      state.view = ["dashboard", "athletes", "recordings", "rank", "settings"].includes(state.view)
        ? state.view
        : "dashboard";
    }
  } catch (error) {
    state.error = error.message || "Gagal mengambil data coach dari API.";
  } finally {
    state.loading = false;
    render();
  }
}

async function login(event) {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const email = String(form.get("email") || "").trim();
  const password = String(form.get("password") || "");
  state.apiBaseUrl = DEFAULT_API_BASE_URL;
  localStorage.setItem("coach_api_base_url", DEFAULT_API_BASE_URL);
  state.loading = true;
  state.error = "";
  render();

  try {
    const data = await request("/login", {
      method: "POST",
      body: JSON.stringify({ email, password, portal: "coach_web" }),
    });
    const payload = data.data || data;
    const user = payload.user || data.user || payload;
    const token = payload.token || data.token || user.token;
    const role = String(user.role || "").toLowerCase();

    if (!token) {
      throw new Error("Token login tidak ditemukan dari response API.");
    }

    if (!["coach", "admin"].includes(role)) {
      throw new Error("Akun ini bukan akun coach/admin.");
    }

    state.token = token;
    state.coachName = user.name || "Coach";
    state.userRole = role;
    state.view = "dashboard";
    localStorage.setItem("coach_token", token);
    localStorage.setItem("coach_name", state.coachName);
    localStorage.setItem("coach_role", role);
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

async function register(event) {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const name = String(form.get("name") || "").trim();
  const email = String(form.get("email") || "").trim().toLowerCase();
  const role = String(form.get("role") || "coach").toLowerCase();
  const password = String(form.get("password") || "");
  const passwordConfirmation = String(form.get("password_confirmation") || "");

  state.apiBaseUrl = DEFAULT_API_BASE_URL;
  localStorage.setItem("coach_api_base_url", DEFAULT_API_BASE_URL);
  state.loading = true;
  state.error = "";
  render();

  try {
    if (!email.endsWith("@gmail.com")) {
      throw new Error("Register wajib memakai akun Gmail.");
    }

    if (!["coach", "admin"].includes(role)) {
      throw new Error("Role register web hanya coach atau admin.");
    }

    const data = await request("/register", {
      method: "POST",
      body: JSON.stringify({
        name,
        email,
        role,
        portal: "coach_web",
        password,
        password_confirmation: passwordConfirmation,
      }),
    });
    const payload = data.data || data;
    const user = payload.user || data.user || payload;
    const token = payload.token || data.token || user.token;
    const registeredRole = String(user.role || role).toLowerCase();

    if (!token) {
      throw new Error("Token register tidak ditemukan dari response API.");
    }

    if (!["coach", "admin"].includes(registeredRole)) {
      throw new Error("Akun baru bukan akun coach/admin.");
    }

    state.token = token;
    state.coachName = user.name || name || "Coach";
    state.userRole = registeredRole;
    state.view = "dashboard";
    localStorage.setItem("coach_token", token);
    localStorage.setItem("coach_name", state.coachName);
    localStorage.setItem("coach_role", registeredRole);
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

function logout() {
  localStorage.removeItem("coach_token");
  localStorage.removeItem("coach_name");
  localStorage.removeItem("coach_role");
  state.token = "";
  state.coachName = "Coach";
  state.userRole = "";
  state.dashboard = null;
  state.athletes = [];
  state.recordings = [];
  state.adminUsers = [];
  state.adminPrograms = [];
  state.adminVideos = [];
  state.adminAthleteVideos = [];
  state.view = "dashboard";
  state.authMode = "login";
  render();
}

function selectView(view) {
  state.view = view;
  state.selectedAthleteId = null;
  render();
}

function selectAthlete(id) {
  state.view = "athletes";
  state.selectedAthleteId = Number(id);
  render();
}

function openReview(id) {
  const recording = state.recordings.find((item) => Number(item.id) === Number(id));
  state.selectedRecordingId = Number(id);
  state.reviewDraft = {
    status: ["needs_revision", "rejected"].includes(recording?.status)
      ? "needs_revision"
      : "approved",
    score: recording?.score || 80,
    feedback: recording?.feedback || "",
  };
  render();
}

function closeReview() {
  state.selectedRecordingId = null;
  render();
}

async function submitReview(event) {
  event.preventDefault();
  const recording = selectedRecording();
  if (!recording) return;

  const form = new FormData(event.currentTarget);
  const status = String(form.get("status") || "approved");
  const score = Number(form.get("score") || 0);
  const feedback = String(form.get("feedback") || "").trim();

  if (!["approved", "needs_revision"].includes(status)) {
    state.error = "Pilih status review yang valid.";
    render();
    return;
  }

  if (!Number.isInteger(score) || score < 0 || score > 100) {
    state.error = "Score review wajib berupa angka bulat 0 sampai 100.";
    render();
    return;
  }

  if (!feedback) {
    state.error = "Catatan coach wajib diisi agar atlet memahami hasil review.";
    render();
    return;
  }

  const payload = { status, score, feedback };
  let reviewResult = null;

  try {
    const response = await request(`/coach/recordings/${recording.id}/review`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
    reviewResult = response.data || {};
  } catch (error) {
    state.error = error.message;
    render();
    return;
  }

  const savedRecording = reviewResult?.recording;
  const savedAthlete = reviewResult?.athlete;
  const savedStatus = savedRecording?.status || (status === "rejected" ? "needs_revision" : status);

  state.recordings = state.recordings.map((item) =>
    Number(item.id) === Number(recording.id)
      ? savedRecording
        ? { ...item, ...savedRecording }
        : {
            ...item,
            status: savedStatus,
            score,
            feedback,
            reviewed_at: new Date().toISOString(),
          }
      : item,
  );

  state.athletes = state.athletes.map((athlete) => {
    if (Number(athlete.id) !== Number(recording.user_id)) return athlete;

    if (savedAthlete) {
      return { ...athlete, ...savedAthlete };
    }

    const nextScore =
      savedStatus === "approved"
        ? Math.round((Number(athlete.performance_progress || 0) + score) / 2)
        : Math.max(0, Math.round(Number(athlete.performance_progress || 0) - 8));
    return {
      ...athlete,
      performance_progress: nextScore,
      pending_reviews: Math.max(0, Number(athlete.pending_reviews || 0) - 1),
    };
  });

  state.dashboard = dashboardFromData(state.athletes, state.recordings);
  state.selectedRecordingId = null;
  state.error = "";
  render();
}

function selectedRecording() {
  return state.recordings.find(
    (recording) => Number(recording.id) === Number(state.selectedRecordingId),
  );
}

function selectedAthlete() {
  return state.athletes.find(
    (athlete) => Number(athlete.id) === Number(state.selectedAthleteId),
  );
}

function filteredAthletes() {
  const query = state.search.trim().toLowerCase();
  if (!query) return state.athletes;
  return state.athletes.filter((athlete) =>
    [athlete.name, athlete.email, athlete.training_level]
      .filter(Boolean)
      .some((value) => String(value).toLowerCase().includes(query)),
  );
}

function recordingsForSelectedAthlete() {
  const athlete = selectedAthlete();
  if (!athlete) return [];
  return state.recordings.filter(
    (recording) => Number(recording.user_id) === Number(athlete.id),
  );
}

function filteredRecordings() {
  const query = state.recordingSearch.trim().toLowerCase();

  return state.recordings.filter((recording) => {
    const statusMatches =
      state.recordingStatusFilter === "all" ||
      recording.status === state.recordingStatusFilter;
    const queryMatches =
      !query ||
      [
        recording.athlete_name,
        recording.athlete_email,
        recording.athlete_training_level,
        recording.user_id,
        recording.workout_title,
        recording.workout_level,
        recording.day_number,
        recording.feedback,
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));

    return statusMatches && queryMatches;
  });
}

function reviewedRecordingsForSelectedAthlete() {
  return recordingsForSelectedAthlete().filter(
    (recording) =>
      recording.status !== "pending" &&
      (recording.reviewed_at || recording.feedback || recording.score !== null),
  );
}

function adminSummary() {
  const programVideos = programVideoRows();
  const exercises = state.adminPrograms.reduce(
    (total, program) => total + Number(program.exercise_count || program.exercises?.length || 0),
    0,
  );

  return {
    users: state.adminUsers.length,
    athletes: state.adminUsers.filter((user) => user.role === "athlete").length,
    coaches: state.adminUsers.filter((user) => user.role === "coach").length,
    admins: state.adminUsers.filter((user) => user.role === "admin").length,
    programs: state.adminPrograms.length,
    exercises,
    videos: programVideos.filter((video) => video.video_url || video.file_url).length,
    pendingAthleteVideos: state.adminAthleteVideos.filter(
      (recording) => recording.status === "pending",
    ).length,
  };
}

function filteredAdminAthleteVideos() {
  const query = state.adminAthleteVideoSearch.trim().toLowerCase();

  return state.adminAthleteVideos.filter((recording) => {
    const statusMatches =
      state.adminAthleteVideoStatusFilter === "all" ||
      recording.status === state.adminAthleteVideoStatusFilter;
    const queryMatches =
      !query ||
      [
        recording.athlete_name,
        recording.athlete_email,
        recording.user_id,
        recording.workout_title,
        recording.day_number,
        recording.status,
        recording.video_url,
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));

    return statusMatches && queryMatches;
  });
}

async function deleteAdminAthleteVideo(id) {
  const recording = state.adminAthleteVideos.find((item) => Number(item.id) === Number(id));
  if (!recording) return;

  const label = `${recording.athlete_name || "atlet"} Day ${recording.day_number || "-"}`;
  if (!confirm(`Hapus video ${label}? File rekaman dan review terkait ikut dihapus.`)) {
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    await request(`/admin/athlete-videos/${id}`, { method: "DELETE" });
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

function filteredAdminUsers() {
  const query = state.adminSearch.trim().toLowerCase();
  return state.adminUsers.filter((user) => {
    const roleMatches =
      state.adminRoleFilter === "all" || user.role === state.adminRoleFilter;
    const queryMatches =
      !query ||
      [user.name, user.email, user.role, user.training_level]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));

    return roleMatches && queryMatches;
  });
}

function resetAdminUserForm() {
  state.editingAdminUserId = null;
  state.adminUserForm = emptyAdminUserForm();
  render();
}

function editAdminUser(id) {
  const user = state.adminUsers.find((item) => Number(item.id) === Number(id));
  if (!user) return;

  state.editingAdminUserId = Number(id);
  state.adminUserForm = {
    name: user.name || "",
    email: user.email || "",
    role: user.role || "coach",
    password: "",
    password_confirmation: "",
    height: user.height ?? "",
    weight: user.weight ?? "",
    age: user.age ?? "",
    training_level: user.training_level || "Beginner",
  };
  render();
}

function adminFormPayload(form) {
  const payload = {
    name: String(form.get("name") || "").trim(),
    email: String(form.get("email") || "").trim().toLowerCase(),
    role: String(form.get("role") || "coach").toLowerCase(),
    height: stringOrNull(form.get("height")),
    weight: stringOrNull(form.get("weight")),
    age: stringOrNull(form.get("age")),
    training_level: stringOrNull(form.get("training_level")),
  };
  const password = String(form.get("password") || "");
  const passwordConfirmation = String(form.get("password_confirmation") || "");

  if (password || passwordConfirmation || !state.editingAdminUserId) {
    payload.password = password;
    payload.password_confirmation = passwordConfirmation;
  }

  return payload;
}

async function submitAdminUser(event) {
  event.preventDefault();
  const payload = adminFormPayload(new FormData(event.currentTarget));
  const editingId = state.editingAdminUserId;

  if (!payload.email.endsWith("@gmail.com")) {
    state.error = "Email wajib menggunakan Gmail.";
    render();
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    await request(editingId ? `/admin/users/${editingId}` : "/admin/users", {
      method: editingId ? "PUT" : "POST",
      body: JSON.stringify(payload),
    });

    state.editingAdminUserId = null;
    state.adminUserForm = emptyAdminUserForm();
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

async function deleteAdminUser(id) {
  const user = state.adminUsers.find((item) => Number(item.id) === Number(id));
  if (!user) return;

  if (!confirm(`Hapus akun ${user.name}?`)) {
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    await request(`/admin/users/${id}`, { method: "DELETE" });
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

function filteredAdminPrograms() {
  const query = state.adminProgramSearch.trim().toLowerCase();
  if (!query) return state.adminPrograms;

  return state.adminPrograms.filter((program) =>
    [program.title, program.name, program.level, program.day_number]
      .filter(Boolean)
      .some((value) => String(value).toLowerCase().includes(query)),
  );
}

function selectedProgram() {
  return state.adminPrograms.find(
    (program) => Number(program.id) === Number(state.selectedProgramId),
  );
}

function resetAdminProgramForm() {
  state.editingAdminProgramId = null;
  state.adminProgramForm = emptyAdminProgramForm();
  render();
}

function editAdminProgram(id) {
  const program = state.adminPrograms.find((item) => Number(item.id) === Number(id));
  if (!program) return;

  state.editingAdminProgramId = Number(id);
  state.selectedProgramId = Number(id);
  state.adminProgramForm = {
    title: program.title || "",
    name: program.name || "",
    level: program.level || "Beginner",
    day_number: program.day_number || "",
  };
  render();
}

async function submitAdminProgram(event) {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const editingId = state.editingAdminProgramId;
  const payload = {
    title: String(form.get("title") || "").trim(),
    name: stringOrNull(form.get("name")),
    level: String(form.get("level") || "Beginner").trim(),
    day_number: Number(form.get("day_number") || 0),
  };

  state.loading = true;
  state.error = "";
  render();

  try {
    const response = await request(
      editingId ? `/admin/programs/${editingId}` : "/admin/programs",
      {
        method: editingId ? "PUT" : "POST",
        body: JSON.stringify(payload),
      },
    );

    state.selectedProgramId = (response.data || response).id || state.selectedProgramId;
    state.editingAdminProgramId = null;
    state.adminProgramForm = emptyAdminProgramForm();
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

async function deleteAdminProgram(id) {
  const program = state.adminPrograms.find((item) => Number(item.id) === Number(id));
  if (!program) return;

  if (!confirm(`Hapus program ${program.title || program.name}?`)) {
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    await request(`/admin/programs/${id}`, { method: "DELETE" });
    if (Number(state.selectedProgramId) === Number(id)) {
      state.selectedProgramId = null;
    }
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

function selectAdminProgram(id) {
  state.selectedProgramId = Number(id);
  state.editingProgramExerciseId = null;
  state.adminProgramExerciseForm = emptyAdminProgramExerciseForm();
  render();
}

function resetProgramExerciseForm() {
  state.editingProgramExerciseId = null;
  state.adminProgramExerciseForm = emptyAdminProgramExerciseForm();
  render();
}

function editProgramExercise(id) {
  const program = selectedProgram();
  const exercise = program?.exercises?.find(
    (item) => Number(item.workout_exercise_id) === Number(id),
  );
  if (!exercise) return;

  state.editingProgramExerciseId = Number(id);
  state.adminProgramExerciseForm = {
    name: exercise.name || "",
    type: exercise.type || "training",
    video_url: exercise.video_url || "",
    sets: exercise.sets || "3",
    reps: exercise.reps || "10",
    duration: exercise.duration ?? "",
    rest_seconds: exercise.rest_seconds ?? "30",
  };
  render();
}

function programExercisePayload(form) {
  return {
    name: String(form.get("name") || "").trim(),
    type: stringOrNull(form.get("type")) || "training",
    video_url: stringOrNull(form.get("video_url")),
    sets: Number(form.get("sets") || 1),
    reps: String(form.get("reps") || "").trim(),
    duration: stringOrNull(form.get("duration")),
    rest_seconds: Number(form.get("rest_seconds") || 0),
  };
}

async function submitProgramExercise(event) {
  event.preventDefault();
  const program = selectedProgram();
  if (!program) return;

  const payload = programExercisePayload(new FormData(event.currentTarget));
  const editingId = state.editingProgramExerciseId;

  if (payload.video_url && !isValidVideoSource(payload.video_url)) {
    state.error = "Video URL harus berupa http(s), /storage/..., atau /videos/....";
    render();
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    await request(
      editingId
        ? `/admin/program-exercises/${editingId}`
        : `/admin/programs/${program.id}/exercises`,
      {
        method: editingId ? "PUT" : "POST",
        body: JSON.stringify(payload),
      },
    );

    state.editingProgramExerciseId = null;
    state.adminProgramExerciseForm = emptyAdminProgramExerciseForm();
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

async function deleteProgramExercise(id) {
  const program = selectedProgram();
  if (!program) return;

  if (!confirm("Hapus exercise dari program ini?")) {
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    await request(`/admin/program-exercises/${id}`, { method: "DELETE" });
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

function programVideoRowsFromPrograms() {
  return state.adminPrograms.flatMap((program) =>
    (program.exercises || []).map((exercise) =>
      normalizeProgramVideoRow({
        ...exercise,
        id: exercise.workout_exercise_id,
        workout_id: program.id,
        workout_title: program.title || program.name,
        program_title: program.title || program.name,
        day_number: program.day_number,
        level: program.level,
        exercise_name: exercise.name,
        exercise_type: exercise.type,
        file_url: exercise.video_url,
      }),
    ),
  );
}

function normalizeProgramVideoRow(video) {
  const id = video.workout_exercise_id || video.id;
  const url = video.video_url || video.file_url || "";

  return {
    ...video,
    id,
    workout_exercise_id: id,
    exercise_name: video.exercise_name || video.name || "-",
    exercise_type: video.exercise_type || video.type || "training",
    workout_title: video.workout_title || video.program_title || `Day ${video.day_number || "-"}`,
    program_title: video.program_title || video.workout_title || `Day ${video.day_number || "-"}`,
    video_url: url,
    file_url: url,
    has_video: Boolean(url),
  };
}

function programVideoRows() {
  const rows = state.adminVideos.length ? state.adminVideos : programVideoRowsFromPrograms();
  return rows.map(normalizeProgramVideoRow);
}

function filteredAdminVideos() {
  const query = state.adminVideoSearch.trim().toLowerCase();
  const rows = programVideoRows();
  if (!query) return rows;

  return rows.filter((video) =>
    [
      video.workout_title,
      video.program_title,
      video.day_number,
      video.level,
      video.exercise_name,
      video.exercise_type,
      video.video_url,
      video.sets,
      video.reps,
    ]
      .filter(Boolean)
      .some((value) => String(value).toLowerCase().includes(query)),
  );
}

function adminVideoProgramKey(video) {
  return String(video.workout_id || `day-${video.day_number || "x"}-${video.workout_title || video.program_title || ""}`);
}

function groupedAdminVideos(rows) {
  const groups = new Map();

  rows.forEach((video) => {
    const key = adminVideoProgramKey(video);
    const existing = groups.get(key);
    const group =
      existing ||
      {
        key,
        workout_id: video.workout_id,
        workout_title: video.workout_title || video.program_title || `Day ${video.day_number || "-"}`,
        program_title: video.program_title || video.workout_title || `Day ${video.day_number || "-"}`,
        day_number: video.day_number,
        level: video.level,
        rows: [],
      };

    group.rows.push(video);
    group.level = group.level || video.level;
    groups.set(key, group);
  });

  return Array.from(groups.values())
    .map((group) => ({
      ...group,
      exercise_count: group.rows.length,
      video_count: group.rows.filter((video) => video.video_url || video.file_url).length,
    }))
    .sort((a, b) => {
      const dayDiff = (Number(a.day_number) || 0) - (Number(b.day_number) || 0);
      if (dayDiff !== 0) return dayDiff;
      return String(a.workout_title).localeCompare(String(b.workout_title));
    });
}

function selectAdminVideoProgram(key) {
  state.selectedVideoProgramKey =
    state.selectedVideoProgramKey === String(key) ? null : String(key);
  render();
}

function resetAdminVideoForm() {
  state.editingAdminVideoId = null;
  state.adminVideoForm = emptyAdminVideoForm();
  state.adminVideoUploadFile = null;
  render();
}

function editAdminVideo(id) {
  const video = programVideoRows().find(
    (item) => Number(item.workout_exercise_id) === Number(id),
  );
  if (!video) return;

  state.editingAdminVideoId = Number(id);
  state.adminVideoForm = {
    workout_exercise_id: video.workout_exercise_id || "",
    video_url: video.video_url || "",
  };
  state.adminVideoUploadFile = null;
  render();
}

function adminVideoPayload(form) {
  const file = state.adminVideoUploadFile || form.get("video");

  return {
    workout_exercise_id: Number(form.get("workout_exercise_id") || 0),
    video_url: String(form.get("video_url") || "").trim(),
    video_file: file instanceof File && file.size > 0 ? file : null,
  };
}

function isVideoUploadFile(file) {
  if (!file) return false;
  if (String(file.type || "").toLowerCase().startsWith("video/")) return true;
  return /\.(mp4|mov|m4v|webm|avi|mkv)$/i.test(file.name || "");
}

function isValidVideoSource(value) {
  const source = String(value || "").trim();
  if (!source) return true;
  if (source.startsWith("/storage/") || source.startsWith("/videos/")) return true;

  try {
    const url = new URL(source);
    return ["http:", "https:"].includes(url.protocol);
  } catch (_) {
    return false;
  }
}

function setAdminVideoUploadFile(file) {
  if (!file) {
    state.adminVideoUploadFile = null;
    render();
    return;
  }

  if (!isVideoUploadFile(file)) {
    state.error = "File yang di-upload harus berupa video.";
    state.adminVideoUploadFile = null;
    render();
    return;
  }


  if (file.size > 512000 * 1024) {
    state.error = "Ukuran file video maksimal 500 MB.";
    state.adminVideoUploadFile = null;
    render();
    return;
  }

  state.error = "";
  state.adminVideoUploadFile = file;
  render();
}

function adminVideoFormData(payload) {
  const formData = new FormData();
  formData.append("workout_exercise_id", String(payload.workout_exercise_id));
  formData.append("video", payload.video_file);

  if (payload.video_url) {
    formData.append("video_url", payload.video_url);
  }

  return formData;
}

async function submitAdminVideo(event) {
  event.preventDefault();
  const payload = adminVideoPayload(new FormData(event.currentTarget));
  const editingId = state.editingAdminVideoId || payload.workout_exercise_id;

  if (!payload.workout_exercise_id) {
    state.error = "Pilih exercise program dulu.";
    render();
    return;
  }

  if (!payload.video_url && !payload.video_file) {
    state.error = "Isi Video URL atau drop file video dulu.";
    render();
    return;
  }


  if (payload.video_url && !isValidVideoSource(payload.video_url)) {
    state.error = "Video URL harus berupa http(s), /storage/..., atau /videos/....";
    render();
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    if (payload.video_file) {
      await request("/admin/videos", {
        method: "POST",
        body: adminVideoFormData(payload),
      });
    } else {
      await request(state.editingAdminVideoId ? `/admin/videos/${editingId}` : "/admin/videos", {
        method: state.editingAdminVideoId ? "PUT" : "POST",
        body: JSON.stringify({
          workout_exercise_id: payload.workout_exercise_id,
          video_url: payload.video_url,
        }),
      });
    }

    state.editingAdminVideoId = null;
    state.adminVideoForm = emptyAdminVideoForm();
    state.adminVideoUploadFile = null;
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

async function deleteAdminVideo(id) {
  const video = programVideoRows().find(
    (item) => Number(item.workout_exercise_id) === Number(id),
  );
  if (!video) return;

  if (!confirm(`Hapus URL video ${video.exercise_name || "exercise"}?`)) {
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    await request(`/admin/videos/${id}`, { method: "DELETE" });
    await loadCoachData();
  } catch (error) {
    state.error = error.message;
    state.loading = false;
    render();
  }
}

function workoutDaysForAthlete(athlete) {
  const recordings = state.recordings.filter(
    (recording) => Number(recording.user_id) === Number(athlete.id),
  );
  const configuredPrograms = Array.isArray(athlete.program_days)
    ? athlete.program_days
        .map((program) => ({
          workoutId: Number(program.workout_id) || null,
          dayNumber: Number(program.day_number) || null,
          title: program.title || `Day ${program.day_number || "-"}`,
          level: program.level || athlete.training_level || null,
        }))
        .filter((program) => program.dayNumber !== null)
    : [];
  const fallbackTotal = Math.max(1, Number(athlete.total_program_days) || 14);
  const fallbackStart =
    String(athlete.training_level || "").toLowerCase() === "intermediate" ? 15 : 1;
  const programs = configuredPrograms.length
    ? configuredPrograms
    : Array.from({ length: fallbackTotal }, (_, index) => ({
        workoutId: null,
        dayNumber: fallbackStart + index,
        title: `Day ${fallbackStart + index}`,
        level: athlete.training_level || null,
      }));

  return programs.map((program) => {
    const dayNumber = program.dayNumber;
    const dayRecordings = recordings
      .filter((item) =>
        program.workoutId
          ? Number(item.workout_id) === program.workoutId
          : Number(item.day_number) === dayNumber,
      )
      .sort((a, b) => new Date(b.uploaded_at || 0) - new Date(a.uploaded_at || 0));
    const recording = dayRecordings[0];

    if (!recording) {
      return {
        dayNumber,
        recordingId: null,
        status: "not_started",
        score: null,
        label: "Belum latihan",
        workoutTitle: program.title,
        workoutLevel: program.level,
      };
    }

    if (recording.status === "approved") {
      return {
        dayNumber,
        recordingId: recording.id,
        status: "approved",
        score: recording.score ?? null,
        label: "Disetujui coach",
        recordingCount: dayRecordings.length,
        workoutTitle: recording.workout_title || program.title,
        workoutLevel: recording.workout_level || program.level,
      };
    }

    if (recording.status === "needs_revision" || recording.status === "rejected") {
      return {
        dayNumber,
        recordingId: recording.id,
        status: "needs_revision",
        score: recording.score ?? null,
        label: "Perlu ulang",
        recordingCount: dayRecordings.length,
        workoutTitle: recording.workout_title || program.title,
        workoutLevel: recording.workout_level || program.level,
      };
    }

    return {
      dayNumber,
      recordingId: recording.id,
      status: "pending",
      score: null,
      label: "Menunggu review",
      recordingCount: dayRecordings.length,
      workoutTitle: recording.workout_title || program.title,
      workoutLevel: recording.workout_level || program.level,
    };
  });
}

function render() {
  const player = currentPlayerRoute();
  if (player) {
    app.innerHTML = renderVideoPlayerPage(player);
    bindVideoPlayerEvents();
    return;
  }

  if (!state.token) {
    app.innerHTML = state.authMode === "register" ? renderRegister() : renderLogin();
    document.querySelector("#login-form")?.addEventListener("submit", login);
    document.querySelector("#register-form")?.addEventListener("submit", register);
    document.querySelector("#auth-mode-toggle")?.addEventListener("click", () => {
      state.authMode = state.authMode === "register" ? "login" : "register";
      state.error = "";
      render();
    });
    return;
  }

  app.innerHTML = `
    <div class="app-shell">
      ${renderSidebar()}
      <main class="main">
        ${state.error ? `<div class="notice">${escapeHtml(state.error)}</div>` : ""}
        ${renderMainView()}
      </main>
    </div>
    ${renderReviewDrawer()}
  `;

  bindShellEvents();
}

function renderLoginLegacy() {
  return `
    <section class="auth-page">
      <div class="auth-shell">
        <div class="auth-brand-mark">
          <div class="auth-logo-ball" aria-hidden="true">🏀</div>
          <div class="auth-brand-title">BPC ELITE</div>
          <div class="auth-brand-line"></div>
        </div>
        <form id="login-form" class="auth-card">
          <h1 class="auth-title">Welcome Back</h1>
          <p class="auth-subtitle">Masuk dengan akun coach/admin untuk memantau training atlet.</p>
          ${state.error ? `<div class="error">${escapeHtml(state.error)}</div>` : ""}
          <div class="field">
            <label for="email">Email</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">@</span>
              <input class="input auth-input" id="email" name="email" type="email" autocomplete="email" placeholder="coach@gmail.com" required />
            </div>
          </div>
          <div class="field">
            <label for="password">Password</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">•</span>
              <input class="input auth-input" id="password" name="password" type="password" autocomplete="current-password" placeholder="Masukkan password" required />
            </div>
          </div>
          <button class="auth-primary" type="submit" ${state.loading ? "disabled" : ""}>
            <span>${state.loading ? "PLEASE WAIT" : "LOGIN"}</span>
            <span aria-hidden="true">${state.loading ? "" : "↗"}</span>
          </button>
          <button class="auth-link-button" id="auth-mode-toggle" type="button">
            Belum punya akun coach/admin? Register
          </button>
        </form>
        <div class="auth-footer">COACH MONITORING DASHBOARD</div>
      </div>
    </section>
  `;
}

function renderRegisterLegacy() {
  return `
    <section class="auth-page">
      <div class="auth-shell auth-shell-wide">
        <div class="auth-brand-mark">
          <div class="auth-logo-ball" aria-hidden="true">B</div>
          <div class="auth-brand-title">BPC ELITE</div>
          <div class="auth-brand-line"></div>
        </div>
        <form id="register-form" class="auth-card">
          <h1 class="auth-title">Register Staff</h1>
          <p class="auth-subtitle">Buat akun khusus coach atau admin. Email wajib Gmail.</p>
          ${state.error ? `<div class="error">${escapeHtml(state.error)}</div>` : ""}
          <div class="field">
            <label for="register-name">Nama</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">N</span>
              <input class="input auth-input" id="register-name" name="name" type="text" autocomplete="name" placeholder="Nama lengkap" required />
            </div>
          </div>
          <div class="field">
            <label for="register-email">Email Gmail</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">@</span>
              <input class="input auth-input" id="register-email" name="email" type="email" autocomplete="email" placeholder="coach@gmail.com" pattern="^[^\\s@]+@gmail\\.com$" required />
            </div>
          </div>
          <div class="field">
            <label for="register-role">Role</label>
            <select class="select auth-input" id="register-role" name="role" required>
              <option value="coach">Coach</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div class="auth-grid">
            <div class="field">
              <label for="register-password">Password</label>
              <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">*</span>
                <input class="input auth-input" id="register-password" name="password" type="password" autocomplete="new-password" placeholder="Minimal 8 karakter" required />
              </div>
            </div>
            <div class="field">
              <label for="register-password-confirmation">Konfirmasi</label>
              <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">*</span>
                <input class="input auth-input" id="register-password-confirmation" name="password_confirmation" type="password" autocomplete="new-password" placeholder="Ulangi password" required />
              </div>
            </div>
          </div>
          <button class="auth-primary" type="submit" ${state.loading ? "disabled" : ""}>
            <span>${state.loading ? "PLEASE WAIT" : "REGISTER"}</span>
            <span aria-hidden="true">${state.loading ? "" : ">"}</span>
          </button>
          <button class="auth-link-button" id="auth-mode-toggle" type="button">
            Sudah punya akun? Login
          </button>
        </form>
        <div class="auth-footer">ADMIN & COACH ACCESS</div>
      </div>
    </section>
  `;
}

function renderLogin() {
  return `
    <section class="auth-page">
      <div class="auth-shell">
        <div class="auth-brand-mark">
          <div class="auth-logo-ball" aria-hidden="true">B</div>
          <div class="auth-brand-title">BPC ELITE</div>
          <div class="auth-brand-line"></div>
        </div>
        <form id="login-form" class="auth-card">
          <h1 class="auth-title">Welcome Back</h1>
          <p class="auth-subtitle">Masuk dengan akun coach/admin untuk memantau training atlet.</p>
          ${state.error ? `<div class="error">${escapeHtml(state.error)}</div>` : ""}
          <div class="field">
            <label for="email">Email</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">@</span>
              <input class="input auth-input" id="email" name="email" type="email" autocomplete="email" placeholder="coach@gmail.com" required />
            </div>
          </div>
          <div class="field">
            <label for="password">Password</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">*</span>
              <input class="input auth-input" id="password" name="password" type="password" autocomplete="current-password" placeholder="Masukkan password" required />
            </div>
          </div>
          <button class="auth-primary" type="submit" ${state.loading ? "disabled" : ""}>
            <span>${state.loading ? "PLEASE WAIT" : "LOGIN"}</span>
            <span aria-hidden="true">${state.loading ? "" : ">"}</span>
          </button>
          <button class="auth-link-button" id="auth-mode-toggle" type="button">
            Belum punya akun coach/admin? Register
          </button>
        </form>
        <div class="auth-footer">COACH MONITORING DASHBOARD</div>
      </div>
    </section>
  `;
}

function renderRegister() {
  return `
    <section class="auth-page">
      <div class="auth-shell auth-shell-wide">
        <div class="auth-brand-mark">
          <div class="auth-logo-ball" aria-hidden="true">B</div>
          <div class="auth-brand-title">BPC ELITE</div>
          <div class="auth-brand-line"></div>
        </div>
        <form id="register-form" class="auth-card">
          <h1 class="auth-title">Register Staff</h1>
          <p class="auth-subtitle">Buat akun khusus coach atau admin. Email wajib Gmail.</p>
          ${state.error ? `<div class="error">${escapeHtml(state.error)}</div>` : ""}
          <div class="field">
            <label for="register-name">Nama</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">N</span>
              <input class="input auth-input" id="register-name" name="name" type="text" autocomplete="name" placeholder="Nama lengkap" required />
            </div>
          </div>
          <div class="field">
            <label for="register-email">Email Gmail</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">@</span>
              <input class="input auth-input" id="register-email" name="email" type="email" autocomplete="email" placeholder="coach@gmail.com" pattern="^[^\\s@]+@gmail\\.com$" required />
            </div>
          </div>
          <div class="field">
            <label for="register-role">Role</label>
            <select class="select auth-input" id="register-role" name="role" required>
              <option value="coach">Coach</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div class="auth-grid">
            <div class="field">
              <label for="register-password">Password</label>
              <div class="auth-input-wrap">
                <span class="auth-input-icon" aria-hidden="true">*</span>
                <input class="input auth-input" id="register-password" name="password" type="password" autocomplete="new-password" placeholder="Minimal 8 karakter" required />
              </div>
            </div>
            <div class="field">
              <label for="register-password-confirmation">Konfirmasi</label>
              <div class="auth-input-wrap">
                <span class="auth-input-icon" aria-hidden="true">*</span>
                <input class="input auth-input" id="register-password-confirmation" name="password_confirmation" type="password" autocomplete="new-password" placeholder="Ulangi password" required />
              </div>
            </div>
          </div>
          <button class="auth-primary" type="submit" ${state.loading ? "disabled" : ""}>
            <span>${state.loading ? "PLEASE WAIT" : "REGISTER"}</span>
            <span aria-hidden="true">${state.loading ? "" : ">"}</span>
          </button>
          <button class="auth-link-button" id="auth-mode-toggle" type="button">
            Sudah punya akun? Login
          </button>
        </form>
        <div class="auth-footer">ADMIN & COACH ACCESS</div>
      </div>
    </section>
  `;
}

function renderSidebar() {
  const nav =
    state.userRole === "admin"
      ? [
          ["dashboard", "D", "Dashboard"],
          ["admin-users", "U", "User"],
          ["admin-programs", "P", "Program"],
          ["admin-videos", "V", "Video"],
          ["admin-athlete-videos", "A", "Video Atlet"],
          ["settings", "S", "API"],
        ]
      : [
          ["dashboard", "D", "Dashboard"],
          ["athletes", "A", "Atlet"],
          ["recordings", "R", "Review"],
          ["rank", "K", "Rank"],
          ["settings", "S", "API"],
        ];

  return `
    <aside class="sidebar">
      <div class="brand">
        <div class="brand-title">${state.userRole === "admin" ? "Admin Monitor" : "Coach Monitor"}</div>
        <div class="brand-subtitle">Halo, ${escapeHtml(state.coachName)} · ${escapeHtml(statusLabel(state.userRole || "coach"))}</div>
      </div>
      <nav class="nav">
        ${nav
          .map(
            ([view, icon, label]) => `
              <button class="nav-button ${state.view === view ? "active" : ""}" data-view="${view}">
                <span class="nav-icon">${icon}</span>
                <span>${label}</span>
              </button>
            `,
          )
        .join("")}
      </nav>
      <div class="sidebar-footer">
        <div class="api-box">
          <div class="api-label">API Aktif</div>
          <div class="api-value">${escapeHtml(state.apiBaseUrl)}</div>
        </div>
        <button class="btn ghost" id="logout-button" type="button">Keluar</button>
      </div>
    </aside>
  `;
}

function renderMainView() {
  const hasAdminData =
    state.adminUsers.length ||
    state.adminPrograms.length ||
    state.adminVideos.length ||
    state.adminAthleteVideos.length;

  if (state.loading && state.userRole === "admin" && !hasAdminData) {
    return `<div class="empty">Memuat data admin...</div>`;
  }

  if (state.loading && state.userRole !== "admin" && !state.dashboard) {
    return `<div class="empty">Memuat data coach...</div>`;
  }

  if (state.view === "athletes") return renderAthletes();
  if (state.view === "recordings") return renderRecordings();
  if (state.view === "rank") return renderRank();
  if (state.view === "admin-users" || state.view === "admin") return renderAdminUsers();
  if (state.view === "admin-programs") return renderAdminPrograms();
  if (state.view === "admin-videos") return renderAdminVideos();
  if (state.view === "admin-athlete-videos") return renderAdminAthleteVideos();
  if (state.view === "settings") return renderSettings();
  return state.userRole === "admin" ? renderAdminDashboard() : renderDashboard();
}

function renderRefreshButton() {
  return `<button class="btn ghost" id="refresh-button" type="button">Muat Ulang</button>`;
}

function renderDashboard() {
  const dashboard = state.dashboard || EMPTY_DASHBOARD;
  const pending = state.recordings.filter((item) => item.status === "pending");
  const attention = state.athletes
    .filter(
      (athlete) =>
        Number(athlete.pending_reviews || 0) > 0 ||
        Number(athlete.performance_progress || 0) < 70,
    )
    .slice(0, 5);

  return `
    ${renderTopbar("Dashboard", "Ringkasan monitoring atlet, review video, dan progress dari coach.", [
      renderRefreshButton(),
    ])}
    <section class="grid kpi-grid">
      ${renderKpi("Total Atlet", dashboard.total_athletes, "Semua atlet terdaftar")}
      ${renderKpi("Atlet Aktif", dashboard.active_athletes, "Memiliki aktivitas dalam 7 hari terakhir")}
      ${renderKpi("Perlu Review", dashboard.pending_reviews, "Video menunggu coach")}
    </section>
    <section class="grid two-col" style="margin-top: 16px">
      <div class="card pad">
        <h2 class="card-title">Review Terbaru</h2>
        ${
          pending.length
            ? `<div class="list">${pending.map(renderRecordingItem).join("")}</div>`
            : `<div class="empty">Tidak ada rekaman pending.</div>`
        }
      </div>
      <div class="card pad">
        <h2 class="card-title">Atlet Perlu Perhatian</h2>
        ${
          attention.length
            ? `<div class="list">${attention.map(renderAttentionItem).join("")}</div>`
            : `<div class="empty">Semua atlet terlihat aman.</div>`
        }
      </div>
    </section>
  `;
}

function renderRank() {
  const dashboard = state.dashboard || EMPTY_DASHBOARD;
  const rankings =
    Array.isArray(dashboard.athlete_rankings) && dashboard.athlete_rankings.length
      ? dashboard.athlete_rankings
      : athleteRankings(state.athletes);

  return `
    ${renderTopbar("Rank", "Ranking atlet berdasarkan consistency dan nilai review coach.", [
      renderRefreshButton(),
    ])}
    <section class="card pad">
      <div class="program-detail-head">
        <div>
          <h2 class="card-title">Ranking Atlet</h2>
          <div class="muted small ranking-note">Skor ranking = 50% consistency + 50% nilai review coach.</div>
        </div>
        <span class="pill info">${escapeHtml(rankings.length)} atlet</span>
      </div>
      ${
        rankings.length
          ? `<div class="list rank-list">${rankings.map(renderRankingItem).join("")}</div>`
          : `<div class="empty">Belum ada atlet untuk diranking.</div>`
      }
    </section>
  `;
}

function renderAdminDashboard() {
  const summary = adminSummary();
  const recentUsers = state.adminUsers.slice(0, 5);
  const programCoverage = groupedAdminVideos(programVideoRows()).slice(0, 5);

  return `
    ${renderTopbar("Dashboard Admin", "Ringkasan user, program, exercise, dan video yang dikelola sistem.", [
      renderRefreshButton(),
    ])}
    <section class="grid kpi-grid">
      ${renderKpi("Total User", summary.users, `${summary.athletes} atlet · ${summary.coaches} coach · ${summary.admins} admin`)}
      ${renderKpi("Total Program", summary.programs, "Program workout yang tersedia")}
      ${renderKpi("Total Exercise", summary.exercises, "Exercise berada di dalam program")}
      ${renderKpi("Video Latihan", summary.videos, "Video preview yang sudah terpasang")}
    </section>
    <section class="grid two-col" style="margin-top: 16px">
      <div class="card pad">
        <div class="program-detail-head">
          <div>
            <h2 class="card-title">Komposisi User</h2>
            <div class="muted small">Role dapat diubah dari menu User.</div>
          </div>
          ${summary.pendingAthleteVideos ? `<span class="pill warning">${escapeHtml(summary.pendingAthleteVideos)} video pending</span>` : `<span class="pill success">Review clear</span>`}
        </div>
        ${
          recentUsers.length
            ? `<div class="list">${recentUsers.map(renderAdminUserSummaryItem).join("")}</div>`
            : `<div class="empty">Belum ada user.</div>`
        }
      </div>
      <div class="card pad">
        <h2 class="card-title">Kelengkapan Video Program</h2>
        ${
          programCoverage.length
            ? `<div class="list">${programCoverage.map(renderProgramCoverageItem).join("")}</div>`
            : `<div class="empty">Belum ada program atau exercise.</div>`
        }
      </div>
    </section>
  `;
}

function renderAthletes() {
  const athlete = selectedAthlete();

  if (athlete) {
    return renderAthleteDetail(athlete);
  }

  return `
    ${renderTopbar("Daftar Atlet", "Pantau konsistensi otomatis dan performance progress dari validasi coach.", [
      renderRefreshButton(),
    ])}
    <section class="card pad">
      <div class="search-row">
        <input class="input search-input" id="athlete-search" placeholder="Cari nama, email, atau level" value="${escapeAttr(state.search)}" />
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Atlet</th>
              <th>Level</th>
              <th>Konsistensi</th>
              <th>Performance</th>
              <th>Review</th>
              <th>Terakhir Latihan</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${filteredAthletes().map(renderAthleteRow).join("")}
          </tbody>
        </table>
      </div>
    </section>
  `;
}

function renderAthleteDetail(athlete) {
  const recordings = recordingsForSelectedAthlete();
  const reviewHistory = reviewedRecordingsForSelectedAthlete();
  const days = workoutDaysForAthlete(athlete);

  return `
    ${renderTopbar(athlete.name, "Detail progress atlet berdasarkan latihan yang dikirim dan review coach.", [
      `<button class="btn ghost" id="back-athletes" type="button">Kembali</button>`,
    ])}
    <section class="grid kpi-grid">
      ${renderKpi("Consistency", `${athlete.consistency_progress || 0}%`, `${athlete.completed_days || 0} selesai dari ${athlete.total_program_days || days.length} workout level ini`)}
      ${renderKpi("Performance", `${athlete.performance_progress || 0}%`, "Dari validasi coach")}
      ${renderKpi("Pending Review", athlete.pending_reviews || 0, "Video belum divalidasi")}
      ${renderKpi("Level", athlete.training_level || "-", "Program aktif atlet")}
    </section>
    <section class="card pad" style="margin-top: 16px">
      <h2 class="card-title">Progress Program ${escapeHtml(athlete.training_level || "Atlet")}</h2>
      <div class="muted small" style="margin-bottom: 12px">${escapeHtml(days.length)} workout mengikuti level dan urutan day pada database.</div>
      <div class="workout-days">
        ${days.map(renderDayTile).join("")}
      </div>
    </section>
    <section class="grid two-col" style="margin-top: 16px">
      <div class="card pad">
        <h2 class="card-title">Rekaman Atlet</h2>
        ${
          recordings.length
            ? `<div class="list">${recordings.map(renderRecordingItem).join("")}</div>`
            : `<div class="empty">Belum ada rekaman dari atlet ini.</div>`
        }
      </div>
      <div class="card pad">
        <h2 class="card-title">Profil</h2>
        <div class="list">
          ${renderProfileLine("Email", athlete.email || "-")}
          ${renderProfileLine("Tinggi", athlete.height ? `${athlete.height} cm` : "-")}
          ${renderProfileLine("Berat", athlete.weight ? `${athlete.weight} kg` : "-")}
          ${renderProfileLine("Usia", athlete.age ? `${athlete.age} tahun` : "-")}
          ${renderProfileLine("Program", `${athlete.training_level || "-"} · ${athlete.total_program_days || days.length} workout`)}
          ${renderProfileLine("Status", statusLabel(athlete.status))}
          ${renderProfileLine("Terakhir latihan", formatDateTime(athlete.last_activity_at))}
          ${renderProfileLine("Catatan", "Performance progress hanya berubah setelah coach memberi review.")}
        </div>
      </div>
    </section>
    <section class="card pad" style="margin-top: 16px">
      <h2 class="card-title">Riwayat Review Coach</h2>
      <div class="muted small" style="margin-bottom: 12px">Bukti evaluasi tersimpan lengkap dengan status, score, feedback, dan waktu review.</div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Workout</th>
              <th>Status</th>
              <th>Score</th>
              <th>Feedback</th>
              <th>Direview</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${
              reviewHistory.length
                ? reviewHistory.map(renderCoachReviewHistoryRow).join("")
                : `<tr><td colspan="6"><div class="empty">Belum ada review coach untuk atlet ini.</div></td></tr>`
            }
          </tbody>
        </table>
      </div>
    </section>
  `;
}

function renderRecordings() {
  const recordings = filteredRecordings();

  return `
    ${renderTopbar("Review Rekaman", "Validasi performance based progress atlet dari hasil live record.", [
      `<select class="select" id="recording-status-filter" style="width: 180px">
        <option value="all" ${state.recordingStatusFilter === "all" ? "selected" : ""}>Semua Status</option>
        <option value="pending" ${state.recordingStatusFilter === "pending" ? "selected" : ""}>Pending</option>
        <option value="approved" ${state.recordingStatusFilter === "approved" ? "selected" : ""}>Approved</option>
        <option value="needs_revision" ${state.recordingStatusFilter === "needs_revision" ? "selected" : ""}>Perlu Ulang</option>
      </select>`,
      renderRefreshButton(),
    ])}
    <section class="card pad">
      <div class="search-row">
        <input class="input search-input" id="recording-search" placeholder="Cari atlet, workout, day, atau feedback" value="${escapeAttr(state.recordingSearch)}" />
        <span class="pill info">${escapeHtml(recordings.length)} rekaman</span>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Atlet</th>
              <th>Workout</th>
              <th>Status</th>
              <th>Score</th>
              <th>Upload</th>
              <th>Durasi</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${
              recordings.length
                ? recordings.map(renderRecordingRow).join("")
                : `<tr><td colspan="7"><div class="empty">Tidak ada rekaman untuk filter ini.</div></td></tr>`
            }
          </tbody>
        </table>
      </div>
    </section>
  `;
}

function renderAdminUsers() {
  if (state.userRole !== "admin") {
    return `<div class="empty">Akses halaman ini hanya untuk admin.</div>`;
  }

  const users = filteredAdminUsers();
  const form = state.adminUserForm;
  const editing = Boolean(state.editingAdminUserId);

  return `
    ${renderTopbar("Admin Users", "Kelola akun admin, coach, dan atlet yang tersambung ke sistem.", [
      renderRefreshButton(),
    ])}
    <section class="grid admin-grid">
      <form id="admin-user-form" class="card pad admin-form">
        <h2 class="card-title">${editing ? "Edit User" : "Tambah User"}</h2>
        <div class="field">
          <label for="admin-name">Nama</label>
          <input class="input" id="admin-name" name="name" value="${escapeAttr(form.name)}" required />
        </div>
        <div class="field">
          <label for="admin-email">Email Gmail</label>
          <input class="input" id="admin-email" name="email" type="email" value="${escapeAttr(form.email)}" pattern="^[^\\s@]+@gmail\\.com$" required />
        </div>
        <div class="field">
          <label for="admin-role">Role</label>
          <select class="select" id="admin-role" name="role">
            ${["athlete", "coach", "admin"]
              .map(
                (role) => `
                  <option value="${role}" ${form.role === role ? "selected" : ""}>${escapeHtml(statusLabel(role))}</option>
                `,
              )
              .join("")}
          </select>
        </div>
        <div class="form-split">
          <div class="field">
            <label for="admin-password">Password</label>
            <input class="input" id="admin-password" name="password" type="password" placeholder="${editing ? "Kosongkan jika tetap" : "Wajib diisi"}" ${editing ? "" : "required"} />
          </div>
          <div class="field">
            <label for="admin-password-confirmation">Konfirmasi</label>
            <input class="input" id="admin-password-confirmation" name="password_confirmation" type="password" placeholder="Ulangi password" ${editing ? "" : "required"} />
          </div>
        </div>
        <div class="form-split">
          <div class="field">
            <label for="admin-height">Tinggi</label>
            <input class="input" id="admin-height" name="height" type="number" min="80" max="250" value="${escapeAttr(form.height)}" />
          </div>
          <div class="field">
            <label for="admin-weight">Berat</label>
            <input class="input" id="admin-weight" name="weight" type="number" min="25" max="250" value="${escapeAttr(form.weight)}" />
          </div>
        </div>
        <div class="form-split">
          <div class="field">
            <label for="admin-age">Usia</label>
            <input class="input" id="admin-age" name="age" type="number" min="8" max="80" value="${escapeAttr(form.age)}" />
          </div>
          <div class="field">
            <label for="admin-training-level">Level Atlet</label>
            <select class="select" id="admin-training-level" name="training_level">
              <option value="">Tidak diisi</option>
              <option value="Beginner" ${form.training_level === "Beginner" ? "selected" : ""}>Beginner</option>
              <option value="Intermediate" ${form.training_level === "Intermediate" ? "selected" : ""}>Intermediate</option>
            </select>
          </div>
        </div>
        <div class="form-actions">
          <button class="btn primary" type="submit" ${state.loading ? "disabled" : ""}>${editing ? "Simpan" : "Tambah"}</button>
          <button class="btn ghost" id="admin-cancel-edit" type="button">Reset</button>
        </div>
      </form>
      <section class="card pad">
        <div class="search-row">
          <input class="input search-input" id="admin-user-search" placeholder="Cari nama, email, role, level" value="${escapeAttr(state.adminSearch)}" />
          <select class="select role-filter" id="admin-role-filter">
            <option value="all" ${state.adminRoleFilter === "all" ? "selected" : ""}>Semua Role</option>
            <option value="athlete" ${state.adminRoleFilter === "athlete" ? "selected" : ""}>Athlete</option>
            <option value="coach" ${state.adminRoleFilter === "coach" ? "selected" : ""}>Coach</option>
            <option value="admin" ${state.adminRoleFilter === "admin" ? "selected" : ""}>Admin</option>
          </select>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Level</th>
                <th>Profil Atlet</th>
                <th>Dibuat</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              ${
                users.length
                  ? users.map(renderAdminUserRow).join("")
                  : `<tr><td colspan="6"><div class="empty">Belum ada user untuk filter ini.</div></td></tr>`
              }
            </tbody>
          </table>
        </div>
      </section>
    </section>
  `;
}

function renderAdminPrograms() {
  if (state.userRole !== "admin") {
    return `<div class="empty">Akses halaman ini hanya untuk admin.</div>`;
  }

  const programs = filteredAdminPrograms();
  const selected = selectedProgram();
  const form = state.adminProgramForm;
  const exerciseForm = state.adminProgramExerciseForm;
  const editing = Boolean(state.editingAdminProgramId);
  const editingExercise = Boolean(state.editingProgramExerciseId);

  return `
    ${renderTopbar("Program", "CRUD workout list, day program, dan exercise yang muncul di aplikasi atlet.", [
      renderRefreshButton(),
    ])}
    <section class="grid admin-grid">
      <div class="grid">
        <form id="admin-program-form" class="card pad admin-form">
          <h2 class="card-title">${editing ? "Edit Program" : "Tambah Program"}</h2>
          <div class="field">
            <label for="program-title">Judul</label>
            <input class="input" id="program-title" name="title" value="${escapeAttr(form.title)}" placeholder="Day 1" required />
          </div>
          <div class="field">
            <label for="program-name">Nama Internal</label>
            <input class="input" id="program-name" name="name" value="${escapeAttr(form.name)}" placeholder="Opsional" />
          </div>
          <div class="form-split">
            <div class="field">
              <label for="program-level">Level</label>
              <select class="select" id="program-level" name="level">
                <option value="Beginner" ${form.level === "Beginner" ? "selected" : ""}>Beginner</option>
                <option value="Intermediate" ${form.level === "Intermediate" ? "selected" : ""}>Intermediate</option>
              </select>
            </div>
            <div class="field">
              <label for="program-day">Day</label>
              <input class="input" id="program-day" name="day_number" type="number" min="1" max="365" value="${escapeAttr(form.day_number)}" required />
            </div>
          </div>
          <div class="form-actions">
            <button class="btn primary" type="submit">${editing ? "Simpan" : "Tambah"}</button>
            <button class="btn ghost" id="program-cancel-edit" type="button">Reset</button>
          </div>
        </form>
        <form id="program-exercise-form" class="card pad admin-form">
          <h2 class="card-title">${editingExercise ? "Edit Exercise" : "Tambah Exercise"}</h2>
          ${
            selected
              ? `<div class="notice">Program aktif: ${escapeHtml(selected.title || selected.name)}.</div>`
              : `<div class="notice">Pilih program dari tabel dulu untuk mengelola exercise.</div>`
          }
          <div class="field">
            <label for="exercise-name">Nama Exercise</label>
            <input class="input" id="exercise-name" name="name" value="${escapeAttr(exerciseForm.name)}" required ${selected ? "" : "disabled"} />
          </div>
          <div class="form-split">
            <div class="field">
              <label for="exercise-type">Tipe</label>
              <input class="input" id="exercise-type" name="type" value="${escapeAttr(exerciseForm.type)}" ${selected ? "" : "disabled"} />
            </div>
            <div class="field">
              <label for="exercise-video-url">Video URL</label>
              <input class="input" id="exercise-video-url" name="video_url" value="${escapeAttr(exerciseForm.video_url)}" ${selected ? "" : "disabled"} />
            </div>
          </div>
          <div class="form-split">
            <div class="field">
              <label for="exercise-sets">Sets</label>
              <input class="input" id="exercise-sets" name="sets" type="number" min="1" max="20" value="${escapeAttr(exerciseForm.sets)}" required ${selected ? "" : "disabled"} />
            </div>
            <div class="field">
              <label for="exercise-reps">Reps</label>
              <input class="input" id="exercise-reps" name="reps" value="${escapeAttr(exerciseForm.reps)}" required ${selected ? "" : "disabled"} />
            </div>
          </div>
          <div class="form-split">
            <div class="field">
              <label for="exercise-duration">Duration</label>
              <input class="input" id="exercise-duration" name="duration" type="number" min="1" max="3600" value="${escapeAttr(exerciseForm.duration)}" ${selected ? "" : "disabled"} />
            </div>
            <div class="field">
              <label for="exercise-rest">Rest</label>
              <input class="input" id="exercise-rest" name="rest_seconds" type="number" min="0" max="3600" value="${escapeAttr(exerciseForm.rest_seconds)}" required ${selected ? "" : "disabled"} />
            </div>
          </div>
          <div class="form-actions">
            <button class="btn primary" type="submit" ${selected ? "" : "disabled"}>${editingExercise ? "Simpan" : "Tambah"}</button>
            <button class="btn ghost" id="exercise-cancel-edit" type="button">Reset</button>
          </div>
        </form>
      </div>
      <section class="card pad">
        <div class="search-row">
          <input class="input search-input" id="admin-program-search" placeholder="Cari day, judul, atau level" value="${escapeAttr(state.adminProgramSearch)}" />
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Program</th>
                <th>Level</th>
                <th>Exercise</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              ${
                programs.length
                  ? programs.map(renderAdminProgramRow).join("")
                  : `<tr><td colspan="4"><div class="empty">Belum ada program.</div></td></tr>`
              }
            </tbody>
          </table>
        </div>
      </section>
    </section>
  `;
}

function renderAdminVideos() {
  if (state.userRole !== "admin") {
    return `<div class="empty">Akses halaman ini hanya untuk admin.</div>`;
  }

  const videos = filteredAdminVideos();
  const videoGroups = groupedAdminVideos(videos);
  const form = state.adminVideoForm;
  const editing = Boolean(state.editingAdminVideoId);
  const exerciseOptions = programVideoRows();
  const uploadFile = state.adminVideoUploadFile;

  return `
    ${renderTopbar("Video", "CRUD video preview untuk workout list di aplikasi atlet.", [
      renderRefreshButton(),
    ])}
    <section class="grid admin-grid">
      <form id="admin-video-form" class="card pad admin-form">
        <h2 class="card-title">${editing ? "Edit Video Latihan" : "Pasang Video Latihan"}</h2>
        <div class="field">
          <label for="video-exercise">Exercise Program</label>
          ${editing ? `<input type="hidden" name="workout_exercise_id" value="${escapeAttr(form.workout_exercise_id)}" />` : ""}
          <select class="select" id="video-exercise" name="workout_exercise_id" required ${editing ? "disabled" : ""}>
            <option value="">Pilih exercise</option>
            ${exerciseOptions
              .map(
                (video) => `
                  <option value="${escapeAttr(video.workout_exercise_id)}" ${Number(form.workout_exercise_id) === Number(video.workout_exercise_id) ? "selected" : ""}>
                    Day ${escapeHtml(video.day_number || "-")} - ${escapeHtml(video.exercise_name || "-")}
                  </option>
                `,
              )
              .join("")}
          </select>
        </div>
        <div class="field">
          <label for="video-url">Video URL</label>
          <input class="input" id="video-url" name="video_url" value="${escapeAttr(form.video_url)}" placeholder="https://... atau /storage/..." />
        </div>
        <div class="field">
          <label for="admin-video-file">Upload Video</label>
          <label class="upload-dropzone" for="admin-video-file" data-video-dropzone>
            <input id="admin-video-file" name="video" type="file" accept="video/*" hidden />
            <span class="upload-dropzone-title">${uploadFile ? escapeHtml(uploadFile.name) : "Drop file video di sini"}</span>
            <span class="upload-dropzone-note">${uploadFile ? `${formatFileSize(uploadFile.size)} siap di-upload` : "atau klik untuk pilih file"}</span>
          </label>
        </div>
        ${
          form.video_url || uploadFile
            ? `<div class="notice">${
                uploadFile
                  ? `File siap upload: ${escapeHtml(uploadFile.name)}`
                  : `Preview aktif: <a class="table-link" href="${escapeAttr(videoPlayerUrl(resolveBackendAssetUrl(form.video_url), { title: "Preview Video Latihan", subtitle: "Video yang sedang diedit", view: "admin-videos" }))}" target="_blank" rel="noreferrer">Buka video</a>`
              }</div>`
            : `<div class="notice">Pilih salah satu sumber: URL http(s)/path server, atau upload file maksimal 500 MB. File upload disimpan backend sebagai path publik <strong>/storage/...</strong>.</div>`
        }
        <div class="form-actions">
          <button class="btn primary" type="submit">${editing ? "Update" : "Pasang"}</button>
          <button class="btn ghost" id="video-cancel-edit" type="button">Reset</button>
        </div>
      </form>
      <section class="card pad">
        <div class="search-row">
          <input class="input search-input" id="admin-video-search" placeholder="Cari day, exercise, tipe, atau URL" value="${escapeAttr(state.adminVideoSearch)}" />
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Program</th>
                <th>Video</th>
                <th>Gerakan</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              ${
                videoGroups.length
                  ? videoGroups.map(renderAdminVideoProgramRow).join("")
                  : `<tr><td colspan="4"><div class="empty">Belum ada program video untuk filter ini.</div></td></tr>`
              }
            </tbody>
          </table>
        </div>
      </section>
    </section>
  `;
}

function renderAdminAthleteVideos() {
  if (state.userRole !== "admin") {
    return `<div class="empty">Akses halaman ini hanya untuk admin.</div>`;
  }

  const videos = filteredAdminAthleteVideos();

  return `
    ${renderTopbar("Video Atlet", "Akses dan hapus rekaman latihan yang di-upload atlet.", [
      renderRefreshButton(),
    ])}
    <section class="card pad">
      <div class="search-row">
        <input class="input search-input" id="admin-athlete-video-search" placeholder="Cari atlet, email, day, status, atau URL" value="${escapeAttr(state.adminAthleteVideoSearch)}" />
        <select class="select role-filter" id="admin-athlete-video-status-filter">
          <option value="all" ${state.adminAthleteVideoStatusFilter === "all" ? "selected" : ""}>Semua Status</option>
          <option value="pending" ${state.adminAthleteVideoStatusFilter === "pending" ? "selected" : ""}>Pending</option>
          <option value="approved" ${state.adminAthleteVideoStatusFilter === "approved" ? "selected" : ""}>Approved</option>
          <option value="needs_revision" ${state.adminAthleteVideoStatusFilter === "needs_revision" ? "selected" : ""}>Perlu Ulang</option>
          <option value="rejected" ${state.adminAthleteVideoStatusFilter === "rejected" ? "selected" : ""}>Rejected</option>
        </select>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Atlet</th>
              <th>Workout</th>
              <th>Status</th>
              <th>Upload</th>
              <th>Durasi</th>
              <th>Ukuran</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${
              videos.length
                ? videos.map(renderAdminAthleteVideoRow).join("")
                : `<tr><td colspan="7"><div class="empty">Belum ada video atlet untuk filter ini.</div></td></tr>`
            }
          </tbody>
        </table>
      </div>
    </section>
  `;
}

function renderSettings() {
  return `
    ${renderTopbar("Pengaturan API", "Atur koneksi backend coach/admin.", [])}
    <section class="card pad">
      <div class="grid" style="max-width: 680px">
        <div class="field">
          <label for="api-setting">API Base URL</label>
          <input class="input" id="api-setting" value="${escapeAttr(state.apiBaseUrl)}" />
        </div>
        <div class="form-actions">
          <button class="btn primary" id="save-api-button" type="button">Simpan API</button>
          <button class="btn ghost" id="fetch-api-button" type="button">Coba Fetch API</button>
        </div>
        <div class="notice">
          Web coach/admin tersambung ke endpoint aplikasi: /coach/dashboard, /coach/athletes, /coach/recordings, /admin/users, /admin/programs, /admin/videos, dan /admin/athlete-videos.
        </div>
      </div>
    </section>
  `;
}

function renderVideoPlayerPage(player) {
  const backUrl = webAppUrl(player.view || state.view || "admin-videos");

  return `
    <section class="player-page">
      <header class="player-bar">
        <a class="btn ghost" href="${escapeAttr(backUrl)}">Web</a>
        <button class="btn primary" id="player-back-button" type="button">Kembali</button>
      </header>
      <main class="player-shell">
        <div class="player-heading">
          <h1>${escapeHtml(player.title || "Preview Video")}</h1>
          <p>${escapeHtml(player.subtitle || "Video preview program latihan")}</p>
        </div>
        <video class="player-video" controls autoplay playsinline>
          <source src="${escapeAttr(player.source)}" type="${escapeAttr(player.mime || "video/mp4")}" />
          Browser tidak mendukung pemutar video.
        </video>
        <div class="video-help player-help">
          <span>Source: ${escapeHtml(player.source)}</span>
          <a href="${escapeAttr(player.source)}" target="_blank" rel="noreferrer">Buka file</a>
        </div>
      </main>
    </section>
  `;
}

function renderTopbar(title, subtitle, actions) {
  return `
    <header class="topbar">
      <div>
        <h1 class="page-title">${escapeHtml(title)}</h1>
        <p class="page-subtitle">${escapeHtml(subtitle)}</p>
      </div>
      <div class="toolbar">${actions.join("")}</div>
    </header>
  `;
}

function renderKpi(label, value, note) {
  return `
    <article class="card kpi-card">
      <div class="kpi-label">${escapeHtml(label)}</div>
      <div class="kpi-value">${escapeHtml(value)}</div>
      <div class="kpi-note">${escapeHtml(note)}</div>
    </article>
  `;
}

function renderAdminUserSummaryItem(user) {
  return `
    <article class="list-item">
      <div class="list-item-row">
        <div>
          <div class="strong">${escapeHtml(user.name || "-")}</div>
          <div class="muted small">${escapeHtml(user.email || "-")}</div>
        </div>
        ${rolePill(user.role)}
      </div>
    </article>
  `;
}

function renderProgramCoverageItem(program) {
  const percentage = program.exercise_count
    ? Math.round((program.video_count / program.exercise_count) * 100)
    : 0;

  return `
    <article class="list-item">
      <div class="list-item-row">
        <div>
          <div class="strong">Day ${escapeHtml(program.day_number || "-")} · ${escapeHtml(program.workout_title || program.program_title || "Program")}</div>
          <div class="muted small">${escapeHtml(program.video_count)} dari ${escapeHtml(program.exercise_count)} exercise memiliki video</div>
        </div>
        <span class="pill ${percentage === 100 ? "success" : "warning"}">${escapeHtml(percentage)}%</span>
      </div>
    </article>
  `;
}

function renderCoachReviewHistoryRow(recording) {
  return `
    <tr>
      <td>
        <div class="name-cell">
          <span class="strong">${escapeHtml(recording.workout_title || `Day ${recording.day_number || "-"}`)}</span>
          <span class="muted small">${escapeHtml(recording.workout_level || recording.athlete_training_level || "-")}</span>
        </div>
      </td>
      <td>${statusPill(recording.status)}</td>
      <td>${recording.score === null || recording.score === undefined ? "-" : `${escapeHtml(recording.score)}%`}</td>
      <td class="feedback-cell">${escapeHtml(recording.feedback || "-")}</td>
      <td>${formatDateTime(recording.reviewed_at)}</td>
      <td><button class="btn ghost" data-review-id="${escapeAttr(recording.id)}" type="button">Lihat/Edit</button></td>
    </tr>
  `;
}

function renderAthleteRow(athlete) {
  return `
    <tr>
      <td>
        <div class="name-cell">
          <span class="strong">${escapeHtml(athlete.name)}</span>
          <span class="muted small">${escapeHtml(athlete.email || "-")}</span>
        </div>
      </td>
      <td>${escapeHtml(athlete.training_level || "-")}</td>
      <td>${renderProgress(athlete.consistency_progress || 0, `${athlete.completed_days || 0}/${athlete.total_program_days || 0} workout`)}</td>
      <td>${renderProgress(athlete.performance_progress || 0, "Performance", true)}</td>
      <td>${renderPendingPill(athlete.pending_reviews || 0)}</td>
      <td>${formatDateTime(athlete.last_activity_at)}</td>
      <td><button class="btn ghost" data-athlete-id="${athlete.id}" type="button">Detail</button></td>
    </tr>
  `;
}

function renderAdminUserRow(user) {
  const profileParts = [
    user.height ? `${user.height}cm` : null,
    user.weight ? `${user.weight}kg` : null,
    user.age ? `${user.age}th` : null,
  ].filter(Boolean);

  return `
    <tr>
      <td>
        <div class="name-cell">
          <span class="strong">${escapeHtml(user.name || "-")}</span>
          <span class="muted small">${escapeHtml(user.email || "-")}</span>
        </div>
      </td>
      <td>${rolePill(user.role)}</td>
      <td>${escapeHtml(user.training_level || "-")}</td>
      <td>${escapeHtml(profileParts.length ? profileParts.join(" / ") : "-")}</td>
      <td>${formatDateTime(user.created_at)}</td>
      <td>
        <div class="row-actions">
          <button class="btn ghost" data-admin-edit="${escapeAttr(user.id)}" type="button">Edit</button>
          <button class="btn danger" data-admin-delete="${escapeAttr(user.id)}" type="button">Hapus</button>
        </div>
      </td>
    </tr>
  `;
}

function renderAdminProgramRow(program) {
  const active = Number(state.selectedProgramId) === Number(program.id);

  return `
    <tr class="program-row ${active ? "active" : ""}">
      <td>
        <div class="name-cell">
          <span class="strong">Day ${escapeHtml(program.day_number)} - ${escapeHtml(program.title || program.name)}</span>
          <span class="muted small">ID ${escapeHtml(program.id)}</span>
        </div>
      </td>
      <td>${escapeHtml(program.level || "-")}</td>
      <td>${escapeHtml(program.exercise_count || 0)} gerakan</td>
      <td>
        <div class="row-actions">
          <button class="btn ${active ? "primary" : "ghost"}" data-program-select="${escapeAttr(program.id)}" type="button">${active ? "Dipilih" : "Pilih"}</button>
          <button class="btn ghost" data-program-edit="${escapeAttr(program.id)}" type="button">Edit</button>
          <button class="btn danger" data-program-delete="${escapeAttr(program.id)}" type="button">Hapus</button>
        </div>
      </td>
    </tr>
    ${active ? renderProgramExerciseDetailRow(program) : ""}
  `;
}

function renderProgramExerciseDetailRow(program) {
  return `
    <tr class="program-detail-row">
      <td colspan="4">
        <div class="program-detail-panel">
          <div class="program-detail-head">
            <div>
              <h2 class="card-title">Detail Gerakan</h2>
              <div class="muted small">Day ${escapeHtml(program.day_number)} - ${escapeHtml(program.title || program.name)}</div>
            </div>
            <span class="pill info">${escapeHtml(program.exercise_count || 0)} gerakan</span>
          </div>
          ${renderProgramExerciseTable(program)}
        </div>
      </td>
    </tr>
  `;
}

function renderProgramExerciseTable(program) {
  const exercises = program.exercises || [];

  if (!exercises.length) {
    return `<div class="empty">Workout list program ini masih kosong.</div>`;
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Exercise</th>
            <th>Sets</th>
            <th>Reps/Duration</th>
            <th>Rest</th>
            <th>Video</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          ${exercises.map(renderProgramExerciseRow).join("")}
        </tbody>
      </table>
    </div>
  `;
}

function renderProgramExerciseRow(exercise) {
  const work = exercise.duration ? `${exercise.duration}s` : exercise.reps || "-";
  const videoUrl = resolveBackendAssetUrl(exercise.video_url);
  const playerUrl = videoPlayerUrl(videoUrl, {
    title: exercise.name || "Preview Video",
    subtitle: "Video workout list",
    view: "admin-programs",
  });

  return `
    <tr>
      <td>
        <div class="name-cell">
          <span class="strong">${escapeHtml(exercise.name || "-")}</span>
          <span class="muted small">${escapeHtml(exercise.type || "training")}</span>
        </div>
      </td>
      <td>${escapeHtml(exercise.sets || 1)}</td>
      <td>${escapeHtml(work)}</td>
      <td>${escapeHtml(exercise.rest_seconds || 0)}s</td>
      <td>${videoUrl ? `<a class="table-link" href="${escapeAttr(playerUrl)}" target="_blank" rel="noreferrer">Buka</a>` : "-"}</td>
      <td>
        <div class="row-actions">
          <button class="btn ghost" data-exercise-edit="${escapeAttr(exercise.workout_exercise_id)}" type="button">Edit</button>
          <button class="btn danger" data-exercise-delete="${escapeAttr(exercise.workout_exercise_id)}" type="button">Hapus</button>
        </div>
      </td>
    </tr>
  `;
}

function renderAdminVideoProgramRow(group) {
  const active = state.selectedVideoProgramKey === String(group.key);

  return `
    <tr class="video-program-row ${active ? "active" : ""}">
      <td>
        <div class="name-cell">
          <span class="strong">Day ${escapeHtml(group.day_number || "-")} - ${escapeHtml(group.workout_title || group.program_title || "-")}</span>
          <span class="muted small">${escapeHtml(group.level || "-")}</span>
        </div>
      </td>
      <td>${escapeHtml(group.video_count)} / ${escapeHtml(group.exercise_count)} video terpasang</td>
      <td>${escapeHtml(group.exercise_count)} gerakan</td>
      <td>
        <div class="row-actions">
          <button class="btn ${active ? "primary" : "ghost"}" data-video-program-detail="${escapeAttr(group.key)}" type="button">${active ? "Tutup" : "Detail"}</button>
        </div>
      </td>
    </tr>
    ${active ? renderAdminVideoDetailRow(group) : ""}
  `;
}

function renderAdminVideoDetailRow(group) {
  return `
    <tr class="program-detail-row">
      <td colspan="4">
        <div class="program-detail-panel">
          <div class="program-detail-head">
            <div>
              <h2 class="card-title">Detail Video</h2>
              <div class="muted small">Day ${escapeHtml(group.day_number || "-")} - ${escapeHtml(group.workout_title || group.program_title || "-")}</div>
            </div>
            <span class="pill info">${escapeHtml(group.video_count)} / ${escapeHtml(group.exercise_count)} video</span>
          </div>
          ${renderAdminVideoExerciseTable(group.rows)}
        </div>
      </td>
    </tr>
  `;
}

function renderAdminVideoExerciseTable(videos) {
  if (!videos.length) {
    return `<div class="empty">Belum ada gerakan untuk day ini.</div>`;
  }

  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Exercise</th>
            <th>Detail</th>
            <th>Video</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          ${videos.map(renderAdminVideoExerciseRow).join("")}
        </tbody>
      </table>
    </div>
  `;
}

function renderAdminVideoExerciseRow(video) {
  const id = video.workout_exercise_id || video.id;
  const work = video.duration ? `${video.duration}s` : video.reps || "-";
  const videoUrl = resolveBackendAssetUrl(video.video_url || video.file_url || "");
  const playerUrl = videoPlayerUrl(videoUrl, {
    title: video.exercise_name || "Preview Video",
    subtitle: `Day ${video.day_number || "-"} - ${video.workout_title || video.program_title || "Program"}`,
    view: "admin-videos",
  });

  return `
    <tr>
      <td>
        <div class="name-cell">
          <span class="strong">${escapeHtml(video.exercise_name || "-")}</span>
          <span class="muted small">${escapeHtml(video.exercise_type || "training")}</span>
        </div>
      </td>
      <td>${escapeHtml(video.sets || 1)} sets / ${escapeHtml(work)} / ${escapeHtml(video.rest_seconds || 0)}s rest</td>
      <td>${
        videoUrl
          ? `<div class="name-cell"><a class="table-link" href="${escapeAttr(playerUrl)}" target="_blank" rel="noreferrer">Buka</a><span class="muted small">${escapeHtml(videoSourceLabel(video.video_url || video.file_url))}</span></div>`
          : `<span class="muted small">Belum ada</span>`
      }</td>
      <td>
        <div class="row-actions">
          <button class="btn ghost" data-video-edit="${escapeAttr(id)}" type="button">Edit</button>
          <button class="btn danger" data-video-delete="${escapeAttr(id)}" type="button" ${videoUrl ? "" : "disabled"}>Hapus</button>
        </div>
      </td>
    </tr>
  `;
}

function renderAdminAthleteVideoRow(recording) {
  const videoUrl = resolveBackendAssetUrl(recording.video_url || recording.file_url || "");
  const playerUrl = videoPlayerUrl(videoUrl, {
    title: `Video ${recording.athlete_name || "Atlet"}`,
    subtitle: `Day ${recording.day_number || "-"} - ${recording.workout_title || "Workout"}`,
    view: "admin-athlete-videos",
    mime: recording.mime_type || "video/webm",
  });

  return `
    <tr>
      <td>
        <div class="name-cell">
          <span class="strong">${escapeHtml(recording.athlete_name || "-")}</span>
          <span class="muted small">${escapeHtml(recording.athlete_email || `ID ${recording.user_id || "-"}`)}</span>
        </div>
      </td>
      <td>
        <div class="name-cell">
          <span class="strong">Day ${escapeHtml(recording.day_number || "-")}</span>
          <span class="muted small">${escapeHtml(recording.workout_title || "Workout")}</span>
        </div>
      </td>
      <td>${statusPill(recording.status)}</td>
      <td>${formatDateTime(recording.uploaded_at)}</td>
      <td>${formatDuration(recording.duration_seconds)}</td>
      <td>${formatFileSize(recording.file_size)}</td>
      <td>
        <div class="row-actions">
          ${
            videoUrl
              ? `<a class="btn primary" href="${escapeAttr(playerUrl)}" target="_blank" rel="noreferrer">Buka</a>`
              : `<button class="btn primary" type="button" disabled>Buka</button>`
          }
          <button class="btn danger" data-athlete-video-delete="${escapeAttr(recording.id)}" type="button">Hapus</button>
        </div>
      </td>
    </tr>
  `;
}

function renderRecordingRow(recording) {
  return `
    <tr>
      <td>
        <div class="name-cell">
          <span class="strong">${escapeHtml(recording.athlete_name || "-")}</span>
          <span class="muted small">${escapeHtml(recording.athlete_email || `ID ${recording.user_id || "-"}`)}</span>
        </div>
      </td>
      <td><div class="name-cell"><span class="strong">${escapeHtml(recording.workout_title || `Day ${recording.day_number || "-"}`)}</span><span class="muted small">${escapeHtml(recording.workout_level || recording.athlete_training_level || "-")}</span></div></td>
      <td>${statusPill(recording.status)}</td>
      <td>${recording.score ? `${escapeHtml(recording.score)}%` : "-"}</td>
      <td>${formatDateTime(recording.uploaded_at)}</td>
      <td>${formatDuration(recording.duration_seconds)}</td>
      <td><button class="btn primary" data-review-id="${recording.id}" type="button">Review</button></td>
    </tr>
  `;
}

function renderRecordingItem(recording) {
  return `
    <article class="list-item">
      <div class="list-item-row">
        <div>
          <div class="strong">${escapeHtml(recording.athlete_name || "-")}</div>
          <div class="muted small">${escapeHtml(recording.workout_title || `Day ${recording.day_number || "-"}`)} · ${escapeHtml(recording.workout_level || recording.athlete_training_level || "-")} · ${formatDateTime(recording.uploaded_at)}</div>
        </div>
        ${statusPill(recording.status)}
      </div>
      <div class="list-item-row">
        <span class="muted small">Durasi ${formatDuration(recording.duration_seconds)}</span>
        <button class="btn primary" data-review-id="${recording.id}" type="button">Review</button>
      </div>
    </article>
  `;
}

function renderAttentionItem(athlete) {
  return `
    <article class="list-item">
      <div class="list-item-row">
        <div>
          <div class="strong">${escapeHtml(athlete.name)}</div>
          <div class="muted small">Performance ${escapeHtml(athlete.performance_progress || 0)}%</div>
        </div>
        ${renderPendingPill(athlete.pending_reviews || 0)}
      </div>
      <button class="btn ghost" data-athlete-id="${athlete.id}" type="button">Lihat Atlet</button>
    </article>
  `;
}

function renderRankingItem(athlete) {
  const reviewLabel =
    Number(athlete.coach_review_count || 0) > 0
      ? `${athlete.coach_review_count} review coach`
      : "Belum ada review coach";

  return `
    <article class="list-item ranking-item">
      <div class="list-item-row">
        <div class="ranking-profile">
          <span class="rank-badge">#${escapeHtml(athlete.rank || "-")}</span>
          <div>
            <div class="strong">${escapeHtml(athlete.name || "-")}</div>
            <div class="muted small">${escapeHtml(athlete.training_level || "-")} · ${escapeHtml(reviewLabel)}</div>
          </div>
        </div>
        <span class="pill success">${escapeHtml(athlete.ranking_score || 0)}%</span>
      </div>
      <div class="ranking-metrics">
        <span>Consistency ${escapeHtml(athlete.consistency_progress || 0)}%</span>
        <span>Review coach ${escapeHtml(athlete.coach_score || 0)}%</span>
        <span>${escapeHtml(athlete.completed_days || 0)}/${escapeHtml(athlete.total_program_days || 0)} hari</span>
      </div>
      <button class="btn ghost" data-athlete-id="${escapeAttr(athlete.id)}" type="button">Detail Atlet</button>
    </article>
  `;
}

function renderDayTile(day) {
  const score =
    day.score === null || day.score === undefined
      ? ""
      : `<span class="score">${escapeHtml(day.score)}%</span>`;
  const countLabel =
    Number(day.recordingCount || 0) > 1
      ? `<span class="muted small">${escapeHtml(day.recordingCount)} rekaman</span>`
      : "";
  const content = `
      <div class="list-item-row">
        <span class="day-number">Day ${day.dayNumber}</span>
        ${score}
      </div>
      ${statusPill(day.status)}
      <span class="strong small">${escapeHtml(day.workoutTitle || `Day ${day.dayNumber}`)}</span>
      <span class="muted small">${escapeHtml(day.label)}</span>
      ${countLabel}
  `;

  if (!day.recordingId) {
    return `<article class="day-tile">${content}</article>`;
  }

  return `
    <button class="day-tile day-tile-button" data-review-id="${escapeAttr(day.recordingId)}" type="button">
      ${content}
      <span class="muted small">Buka penilaian</span>
    </button>
  `;
}

function renderProfileLine(label, value) {
  return `
    <div class="list-item-row">
      <span class="muted">${escapeHtml(label)}</span>
      <span class="strong">${escapeHtml(value)}</span>
    </div>
  `;
}

function renderProgress(value, label, performance = false) {
  const safeValue = Math.max(0, Math.min(100, Number(value) || 0));
  return `
    <div class="progress">
      <div class="progress-line">
        <div class="progress-fill ${performance ? "performance" : ""}" style="width: ${safeValue}%"></div>
      </div>
      <div class="progress-meta">
        <span>${escapeHtml(label)}</span>
        <span>${safeValue}%</span>
      </div>
    </div>
  `;
}

function renderPendingPill(value) {
  const count = Number(value) || 0;
  if (count <= 0) return `<span class="pill success">Clear</span>`;
  return `<span class="pill warning">${count} review</span>`;
}

function statusPill(status) {
  const normalized = String(status || "pending").toLowerCase();
  const map = {
    active: ["Aktif", "success"],
    approved: ["Approved", "success"],
    clear: ["Clear", "success"],
    pending: ["Pending", "warning"],
    pending_review: ["Pending", "warning"],
    needs_attention: ["Perlu Perhatian", "danger"],
    needs_revision: ["Perlu Ulang", "danger"],
    rejected: ["Perlu Ulang", "danger"],
    not_started: ["Belum Mulai", ""],
  };
  const [label, className] = map[normalized] || [statusLabel(status), "info"];
  return `<span class="pill ${className}">${escapeHtml(label)}</span>`;
}

function rolePill(role) {
  const normalized = String(role || "athlete").toLowerCase();
  const map = {
    admin: ["Admin", "danger"],
    coach: ["Coach", "info"],
    athlete: ["Athlete", "success"],
  };
  const [label, className] = map[normalized] || [statusLabel(role), ""];
  return `<span class="pill ${className}">${escapeHtml(label)}</span>`;
}

function statusLabel(status) {
  return String(status || "-")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function renderReviewDrawer() {
  const recording = selectedRecording();
  if (!recording) return `<div class="drawer"></div>`;
  const videoUrl = resolveBackendAssetUrl(recording.video_url);

  return `
    <div class="drawer open">
      <section class="drawer-panel">
        <div class="drawer-head">
          <div>
            <h2 class="card-title">Review ${escapeHtml(recording.athlete_name || "-")}</h2>
            <div class="muted small">Day ${escapeHtml(recording.day_number || "-")} - ${formatDateTime(recording.uploaded_at)}</div>
          </div>
          <button class="btn ghost" id="close-review" type="button">Tutup</button>
        </div>
        <div class="drawer-body">
          <video class="video-frame" id="review-video" controls preload="metadata" playsinline>
            <source src="${escapeAttr(videoUrl)}" type="${escapeAttr(recording.mime_type || "video/webm")}">
          </video>
          <div class="video-help">
            <span id="video-status">Video source: ${escapeHtml(videoUrl || "tidak tersedia")}</span>
            ${videoUrl ? `<a href="${escapeAttr(videoUrl)}" target="_blank" rel="noreferrer">Buka file</a>` : ""}
          </div>
          <form id="review-form" class="review-form">
            <div class="field">
              <label for="review-status">Validasi</label>
              <select class="select" id="review-status" name="status" required>
                <option value="approved" ${state.reviewDraft.status === "approved" ? "selected" : ""}>Approved</option>
                <option value="needs_revision" ${state.reviewDraft.status === "needs_revision" ? "selected" : ""}>Perlu Ulang</option>
              </select>
            </div>
            <div class="field">
              <label for="review-score">Score Performance</label>
              <input class="input" id="review-score" name="score" type="number" min="0" max="100" value="${escapeAttr(state.reviewDraft.score)}" required />
            </div>
            <div class="field full">
              <label for="review-feedback">Catatan Coach</label>
              <textarea class="textarea" id="review-feedback" name="feedback" maxlength="2000" required placeholder="Wajib diisi. Contoh: landing sudah stabil, tapi start sprint perlu lebih eksplosif.">${escapeHtml(state.reviewDraft.feedback)}</textarea>
            </div>
            <div class="form-actions full">
              <button class="btn success" type="submit">Simpan Review</button>
              <button class="btn ghost" id="cancel-review" type="button">Batal</button>
            </div>
          </form>
        </div>
      </section>
    </div>
  `;
}

function bindShellEvents() {
  document.querySelectorAll("[data-view]").forEach((button) => {
    button.addEventListener("click", () => selectView(button.dataset.view));
  });

  document.querySelector("#logout-button")?.addEventListener("click", logout);
  document
    .querySelector("#refresh-button")
    ?.addEventListener("click", () => loadCoachData());
  document
    .querySelector("#fetch-api-button")
    ?.addEventListener("click", () => loadCoachData());
  document.querySelectorAll("[data-athlete-id]").forEach((button) => {
    button.addEventListener("click", () => selectAthlete(button.dataset.athleteId));
  });
  document.querySelectorAll("[data-review-id]").forEach((button) => {
    button.addEventListener("click", () => openReview(button.dataset.reviewId));
  });
  document.querySelectorAll("[data-admin-edit]").forEach((button) => {
    button.addEventListener("click", () => editAdminUser(button.dataset.adminEdit));
  });
  document.querySelectorAll("[data-admin-delete]").forEach((button) => {
    button.addEventListener("click", () => deleteAdminUser(button.dataset.adminDelete));
  });
  document.querySelectorAll("[data-program-select]").forEach((button) => {
    button.addEventListener("click", () => selectAdminProgram(button.dataset.programSelect));
  });
  document.querySelectorAll("[data-program-edit]").forEach((button) => {
    button.addEventListener("click", () => editAdminProgram(button.dataset.programEdit));
  });
  document.querySelectorAll("[data-program-delete]").forEach((button) => {
    button.addEventListener("click", () => deleteAdminProgram(button.dataset.programDelete));
  });
  document.querySelectorAll("[data-exercise-edit]").forEach((button) => {
    button.addEventListener("click", () => editProgramExercise(button.dataset.exerciseEdit));
  });
  document.querySelectorAll("[data-exercise-delete]").forEach((button) => {
    button.addEventListener("click", () =>
      deleteProgramExercise(button.dataset.exerciseDelete),
    );
  });
  document.querySelectorAll("[data-video-edit]").forEach((button) => {
    button.addEventListener("click", () => editAdminVideo(button.dataset.videoEdit));
  });
  document.querySelectorAll("[data-video-delete]").forEach((button) => {
    button.addEventListener("click", () => deleteAdminVideo(button.dataset.videoDelete));
  });
  document.querySelectorAll("[data-athlete-video-delete]").forEach((button) => {
    button.addEventListener("click", () =>
      deleteAdminAthleteVideo(button.dataset.athleteVideoDelete),
    );
  });
  document.querySelectorAll("[data-video-program-detail]").forEach((button) => {
    button.addEventListener("click", () =>
      selectAdminVideoProgram(button.dataset.videoProgramDetail),
    );
  });

  document.querySelector("#athlete-search")?.addEventListener("input", (event) => {
    state.search = event.target.value;
    render();
  });
  document.querySelector("#recording-search")?.addEventListener("input", (event) => {
    state.recordingSearch = event.target.value;
    render();
  });
  document.querySelector("#admin-user-search")?.addEventListener("input", (event) => {
    state.adminSearch = event.target.value;
    render();
  });
  document.querySelector("#admin-role-filter")?.addEventListener("change", (event) => {
    state.adminRoleFilter = event.target.value;
    render();
  });
  document.querySelector("#admin-program-search")?.addEventListener("input", (event) => {
    state.adminProgramSearch = event.target.value;
    render();
  });
  document.querySelector("#admin-video-search")?.addEventListener("input", (event) => {
    state.adminVideoSearch = event.target.value;
    render();
  });
  document
    .querySelector("#admin-athlete-video-search")
    ?.addEventListener("input", (event) => {
      state.adminAthleteVideoSearch = event.target.value;
      render();
    });
  document
    .querySelector("#admin-athlete-video-status-filter")
    ?.addEventListener("change", (event) => {
      state.adminAthleteVideoStatusFilter = event.target.value;
      render();
    });
  document.querySelector("#admin-user-form")?.addEventListener("submit", submitAdminUser);
  document.querySelector("#admin-cancel-edit")?.addEventListener("click", resetAdminUserForm);
  document.querySelector("#admin-program-form")?.addEventListener("submit", submitAdminProgram);
  document
    .querySelector("#program-cancel-edit")
    ?.addEventListener("click", resetAdminProgramForm);
  document
    .querySelector("#program-exercise-form")
    ?.addEventListener("submit", submitProgramExercise);
  document
    .querySelector("#exercise-cancel-edit")
    ?.addEventListener("click", resetProgramExerciseForm);
  document.querySelector("#admin-video-form")?.addEventListener("submit", submitAdminVideo);
  document.querySelector("#video-cancel-edit")?.addEventListener("click", resetAdminVideoForm);
  document.querySelector("#admin-video-file")?.addEventListener("change", (event) => {
    setAdminVideoUploadFile(event.target.files?.[0] || null);
  });

  const videoDropzone = document.querySelector("[data-video-dropzone]");
  if (videoDropzone) {
    ["dragenter", "dragover"].forEach((eventName) => {
      videoDropzone.addEventListener(eventName, (event) => {
        event.preventDefault();
        videoDropzone.classList.add("dragging");
      });
    });
    ["dragleave", "dragend"].forEach((eventName) => {
      videoDropzone.addEventListener(eventName, (event) => {
        event.preventDefault();
        videoDropzone.classList.remove("dragging");
      });
    });
    videoDropzone.addEventListener("drop", (event) => {
      event.preventDefault();
      videoDropzone.classList.remove("dragging");
      setAdminVideoUploadFile(event.dataTransfer?.files?.[0] || null);
    });
  }

  document.querySelector("#back-athletes")?.addEventListener("click", () => {
    state.selectedAthleteId = null;
    render();
  });

  document.querySelector("#save-api-button")?.addEventListener("click", () => {
    const value = document.querySelector("#api-setting")?.value || DEFAULT_API_BASE_URL;
    state.apiBaseUrl = value.trim().replace(/\/$/, "");
    localStorage.setItem("coach_api_base_url", state.apiBaseUrl);
    render();
  });

  document
    .querySelector("#recording-status-filter")
    ?.addEventListener("change", (event) => {
      state.recordingStatusFilter = event.target.value;
      render();
    });

  document.querySelector("#close-review")?.addEventListener("click", closeReview);
  document.querySelector("#cancel-review")?.addEventListener("click", closeReview);
  document.querySelector("#review-form")?.addEventListener("submit", submitReview);
  const reviewVideo = document.querySelector("#review-video");
  reviewVideo?.addEventListener("loadedmetadata", () => {
    const status = document.querySelector("#video-status");
    if (status) {
      status.textContent = "Video siap diputar.";
    }
  });
  reviewVideo?.addEventListener("error", () => {
    const status = document.querySelector("#video-status");
    if (status) {
      status.textContent =
        "Video gagal dimuat. Klik Buka file untuk cek URL langsung.";
    }
  });
}

function bindVideoPlayerEvents() {
  document.querySelector("#player-back-button")?.addEventListener("click", () => {
    if (window.history.length > 1) {
      window.history.back();
      return;
    }

    const player = currentPlayerRoute();
    window.location.href = webAppUrl(
      player?.view || (state.userRole === "admin" ? "admin-videos" : "recordings"),
    );
  });
}

function formatDateTime(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

function formatDuration(value) {
  const seconds = Number(value);
  if (!Number.isFinite(seconds) || seconds <= 0) return "-";
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;
  return minutes > 0 ? `${minutes}m ${rest}s` : `${rest}s`;
}

function formatFileSize(value) {
  const bytes = Number(value);
  if (!Number.isFinite(bytes) || bytes <= 0) return "-";

  if (bytes >= 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  return `${Math.max(1, Math.round(bytes / 1024))} KB`;
}

function stringOrNull(value) {
  const text = String(value ?? "").trim();
  return text === "" ? null : text;
}

function isViewAllowedForRole(view, role) {
  const adminViews = [
    "dashboard",
    "admin-users",
    "admin-programs",
    "admin-videos",
    "admin-athlete-videos",
    "settings",
  ];
  const coachViews = ["dashboard", "athletes", "recordings", "rank", "settings"];

  return role === "admin" ? adminViews.includes(view) : coachViews.includes(view);
}

function videoSourceLabel(value) {
  const source = String(value || "").trim();
  if (!source) return "Belum ada sumber";
  if (source.startsWith("/storage/") || source.includes("/storage/")) {
    return "File upload · disimpan sebagai path /storage";
  }
  if (source.startsWith("/videos/") || source.includes("/videos/")) {
    return "File server · path /videos";
  }
  return "URL eksternal";
}

function webAppUrl(view) {
  const url = new URL(window.location.href);
  url.search = "";
  url.hash = "";

  if (view) {
    url.searchParams.set("view", view);
  }

  return url.toString();
}

function videoPlayerUrl(source, options = {}) {
  if (!source) return "";

  const url = new URL(window.location.href);
  url.search = "";
  url.hash = "";
  url.searchParams.set("player", source);

  if (options.title) url.searchParams.set("title", options.title);
  if (options.subtitle) url.searchParams.set("subtitle", options.subtitle);
  if (options.view) url.searchParams.set("view", options.view);
  if (options.mime) url.searchParams.set("mime", options.mime);

  return url.toString();
}

function currentPlayerRoute() {
  const params = new URLSearchParams(window.location.search);
  const source = params.get("player");
  if (!source) return null;

  return {
    source: resolveBackendAssetUrl(source),
    title: params.get("title") || "Preview Video",
    subtitle: params.get("subtitle") || "Video preview program latihan",
    view: params.get("view") || "",
    mime: params.get("mime") || "video/mp4",
  };
}

function backendOrigin() {
  const base = String(state.apiBaseUrl || DEFAULT_API_BASE_URL)
    .replace(/\/api\/?$/i, "")
    .replace(/\/$/, "");

  try {
    return new URL(base).origin;
  } catch (_) {
    return base;
  }
}

function resolveBackendAssetUrl(value) {
  const raw = String(value ?? "").trim();
  if (!raw) return "";

  const origin = backendOrigin();

  if (/^https?:\/\//i.test(raw)) {
    try {
      const url = new URL(raw);
      const backend = new URL(origin);
      const isLocalhost = ["127.0.0.1", "localhost", "0.0.0.0"].includes(
        url.hostname,
      );
      const isBackendAsset =
        url.pathname.startsWith("/videos/") || url.pathname.startsWith("/storage/");

      if (isLocalhost && isBackendAsset) {
        url.protocol = backend.protocol;
        url.hostname = backend.hostname;
        url.port = backend.port;
        return url.toString();
      }
    } catch (_) {
      return raw;
    }

    return raw;
  }

  const path = raw.startsWith("/") ? raw : `/${raw}`;
  return `${origin}${path}`;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function escapeAttr(value) {
  return escapeHtml(value);
}

if (state.token) {
  loadCoachData();
} else {
  render();
}
