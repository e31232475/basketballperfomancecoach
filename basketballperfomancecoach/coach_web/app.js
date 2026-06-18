const DEFAULT_API_BASE_URL = "http://127.0.0.1:8001/api";
const DEMO_STATE_KEY = "coach_demo_state_v1";
const storedApiBaseUrl = localStorage.getItem("coach_api_base_url");
const initialApiBaseUrl =
  !storedApiBaseUrl || storedApiBaseUrl === "http://127.0.0.1:8000/api"
    ? DEFAULT_API_BASE_URL
    : storedApiBaseUrl;

if (storedApiBaseUrl !== initialApiBaseUrl) {
  localStorage.setItem("coach_api_base_url", initialApiBaseUrl);
}

const demoData = {
  dashboard: {
    total_athletes: 18,
    active_athletes: 12,
    pending_reviews: 5,
    average_performance: 78,
    average_consistency: 64,
  },
  athletes: [
    {
      id: 1,
      name: "Dimas Ramdhan",
      email: "dimas@gmail.com",
      training_level: "Beginner",
      consistency_progress: 71,
      performance_progress: 82,
      pending_reviews: 1,
      last_activity_at: "2026-06-08T08:40:00+07:00",
      status: "active",
    },
    {
      id: 2,
      name: "Raka Pratama",
      email: "raka@gmail.com",
      training_level: "Beginner",
      consistency_progress: 43,
      performance_progress: 67,
      pending_reviews: 2,
      last_activity_at: "2026-06-07T19:12:00+07:00",
      status: "needs_attention",
    },
    {
      id: 3,
      name: "Naufal Akbar",
      email: "naufal@gmail.com",
      training_level: "Beginner",
      consistency_progress: 86,
      performance_progress: 91,
      pending_reviews: 0,
      last_activity_at: "2026-06-08T06:15:00+07:00",
      status: "active",
    },
  ],
  recordings: [
    {
      id: 101,
      user_id: 1,
      athlete_name: "Dimas Ramdhan",
      workout_id: 11,
      day_number: 5,
      workout_title: "Day 5",
      uploaded_at: "2026-06-08T08:40:00+07:00",
      status: "pending",
      duration_seconds: 74,
      video_url:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    },
    {
      id: 102,
      user_id: 2,
      athlete_name: "Raka Pratama",
      workout_id: 12,
      day_number: 3,
      workout_title: "Day 3",
      uploaded_at: "2026-06-07T19:12:00+07:00",
      status: "pending",
      duration_seconds: 63,
      video_url:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    },
    {
      id: 103,
      user_id: 3,
      athlete_name: "Naufal Akbar",
      workout_id: 13,
      day_number: 8,
      workout_title: "Day 8",
      uploaded_at: "2026-06-08T06:15:00+07:00",
      status: "approved",
      score: 91,
      feedback: "Landing sudah stabil dan ritme latihan konsisten.",
      duration_seconds: 81,
      video_url:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    },
  ],
  adminUsers: [
    {
      id: 901,
      name: "Admin BPC",
      email: "adminbpc@gmail.com",
      role: "admin",
      training_level: null,
      height: null,
      weight: null,
      age: null,
      personalization_completed: true,
      created_at: "2026-06-08T06:00:00+07:00",
    },
    {
      id: 902,
      name: "Coach Elite",
      email: "coachelite@gmail.com",
      role: "coach",
      training_level: null,
      height: null,
      weight: null,
      age: null,
      personalization_completed: true,
      created_at: "2026-06-08T06:10:00+07:00",
    },
    {
      id: 1,
      name: "Dimas Ramdhan",
      email: "dimas@gmail.com",
      role: "athlete",
      training_level: "Beginner",
      height: 180,
      weight: 75,
      age: 20,
      personalization_completed: true,
      created_at: "2026-06-08T06:20:00+07:00",
    },
  ],
  adminPrograms: [
    {
      id: 11,
      title: "Day 1",
      name: "Day 1",
      level: "Beginner",
      day_number: 1,
      exercise_count: 2,
      exercises: [
        {
          workout_exercise_id: 1001,
          exercise_id: 501,
          name: "Sprint 15 Meter",
          type: "training",
          video_url:
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
          sets: 4,
          reps: "15 meter",
          duration: null,
          rest_seconds: 30,
        },
        {
          workout_exercise_id: 1002,
          exercise_id: 502,
          name: "Tuck Jump",
          type: "training",
          video_url:
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
          sets: 3,
          reps: "8",
          duration: null,
          rest_seconds: 30,
        },
      ],
    },
  ],
  adminVideos: [
    {
      id: 1001,
      workout_exercise_id: 1001,
      exercise_id: 501,
      workout_id: 11,
      workout_title: "Day 1",
      program_title: "Day 1",
      day_number: 1,
      level: "Beginner",
      exercise_name: "Sprint 15 Meter",
      exercise_type: "training",
      video_url:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
      file_url:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
      sets: 4,
      reps: "15 meter",
      duration: null,
      rest_seconds: 30,
      has_video: true,
    },
    {
      id: 1002,
      workout_exercise_id: 1002,
      exercise_id: 502,
      workout_id: 11,
      workout_title: "Day 1",
      program_title: "Day 1",
      day_number: 1,
      level: "Beginner",
      exercise_name: "Tuck Jump",
      exercise_type: "training",
      video_url:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      file_url:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      sets: 3,
      reps: "8",
      duration: null,
      rest_seconds: 30,
      has_video: true,
    },
  ],
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
  view: localStorage.getItem("coach_role") === "admin" ? "admin-users" : "dashboard",
  authMode: "login",
  apiBaseUrl: initialApiBaseUrl,
  token: localStorage.getItem("coach_token") || "",
  coachName: localStorage.getItem("coach_name") || "Coach",
  userRole: localStorage.getItem("coach_role") || "",
  demoMode: localStorage.getItem("coach_demo_mode") === "true",
  loading: false,
  error: "",
  dashboard: null,
  athletes: [],
  recordings: [],
  adminUsers: [],
  adminPrograms: [],
  adminVideos: [],
  selectedAthleteId: null,
  selectedRecordingId: null,
  selectedProgramId: null,
  selectedVideoProgramKey: null,
  search: "",
  recordingStatusFilter: "all",
  adminSearch: "",
  adminRoleFilter: "all",
  adminProgramSearch: "",
  adminVideoSearch: "",
  editingAdminUserId: null,
  adminUserForm: emptyAdminUserForm(),
  editingAdminProgramId: null,
  adminProgramForm: emptyAdminProgramForm(),
  editingProgramExerciseId: null,
  adminProgramExerciseForm: emptyAdminProgramExerciseForm(),
  editingAdminVideoId: null,
  adminVideoForm: emptyAdminVideoForm(),
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

if (state.token === "demo-token") {
  state.token = "";
  state.coachName = "Coach";
  state.userRole = "";
  state.demoMode = false;
  localStorage.removeItem("coach_token");
  localStorage.removeItem("coach_name");
  localStorage.removeItem("coach_role");
  localStorage.setItem("coach_demo_mode", "false");
}

if (state.token && !["coach", "admin"].includes(state.userRole)) {
  state.token = "";
  state.coachName = "Coach";
  state.userRole = "";
  state.demoMode = false;
  localStorage.removeItem("coach_token");
  localStorage.removeItem("coach_name");
  localStorage.removeItem("coach_role");
  localStorage.setItem("coach_demo_mode", "false");
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

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function demoSnapshot() {
  try {
    const stored = JSON.parse(localStorage.getItem(DEMO_STATE_KEY) || "null");
    if (stored && Array.isArray(stored.athletes) && Array.isArray(stored.recordings)) {
      return stored;
    }
  } catch (_) {
    localStorage.removeItem(DEMO_STATE_KEY);
  }

  return clone({
    dashboard: demoData.dashboard,
    athletes: demoData.athletes,
    recordings: demoData.recordings,
    adminUsers: demoData.adminUsers,
    adminPrograms: demoData.adminPrograms,
    adminVideos: demoData.adminVideos,
  });
}

function persistDemoSnapshot() {
  if (!state.demoMode) return;
  localStorage.setItem(
    DEMO_STATE_KEY,
    JSON.stringify({
      dashboard: state.dashboard,
      athletes: state.athletes,
      recordings: state.recordings,
      adminUsers: state.adminUsers,
      adminPrograms: state.adminPrograms,
      adminVideos: state.adminVideos,
    }),
  );
}

function resetDemoSnapshot() {
  localStorage.removeItem(DEMO_STATE_KEY);
  state.demoMode = true;
  localStorage.setItem("coach_demo_mode", "true");
  loadCoachData();
}

function dashboardFromData(athletes, recordings) {
  const totalAthletes = athletes.length;
  const pendingReviews = recordings.filter((item) => item.status === "pending").length;
  const activeAthletes = athletes.filter((athlete) => athlete.last_activity_at).length;
  const averagePerformance = totalAthletes
    ? Math.round(
        athletes.reduce(
          (sum, athlete) => sum + Number(athlete.performance_progress || 0),
          0,
        ) / totalAthletes,
      )
    : 0;
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
    average_performance: averagePerformance,
    average_consistency: averageConsistency,
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
    throw new Error(body.message || `Request gagal (${response.status})`);
  }

  return body;
}

async function loadCoachData({ forceApi = false } = {}) {
  state.loading = true;
  state.error = "";
  render();

  if (state.demoMode && !forceApi) {
    await delay(250);
    const snapshot = demoSnapshot();
    state.athletes = snapshot.athletes;
    state.recordings = snapshot.recordings;
    state.adminUsers = snapshot.adminUsers || demoData.adminUsers;
    state.adminPrograms = snapshot.adminPrograms || demoData.adminPrograms;
    state.adminVideos = snapshot.adminVideos || demoData.adminVideos;
    state.dashboard =
      snapshot.dashboard || dashboardFromData(state.athletes, state.recordings);
    state.loading = false;
    render();
    return;
  }

  try {
    if (state.userRole === "admin") {
      const [adminUsers, adminPrograms, adminVideos] = await Promise.all([
        request("/admin/users"),
        request("/admin/programs"),
        request("/admin/videos"),
      ]);

      state.adminUsers = normalizeList(adminUsers);
      state.adminPrograms = normalizeList(adminPrograms);
      state.adminVideos = normalizeList(adminVideos);
      state.dashboard = null;
      state.athletes = [];
      state.recordings = [];
      state.view = ["admin-users", "admin-programs", "admin-videos", "settings"].includes(
        state.view,
      )
        ? state.view
        : "admin-users";
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
      state.view = ["dashboard", "athletes", "recordings", "settings"].includes(state.view)
        ? state.view
        : "dashboard";
    }
    state.demoMode = false;
    localStorage.setItem("coach_demo_mode", "false");
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
    state.view = role === "admin" ? "admin-users" : "dashboard";
    state.demoMode = false;
    localStorage.setItem("coach_token", token);
    localStorage.setItem("coach_name", state.coachName);
    localStorage.setItem("coach_role", role);
    localStorage.setItem("coach_demo_mode", "false");
    await loadCoachData({ forceApi: true });
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
    state.view = registeredRole === "admin" ? "admin-users" : "dashboard";
    state.demoMode = false;
    localStorage.setItem("coach_token", token);
    localStorage.setItem("coach_name", state.coachName);
    localStorage.setItem("coach_role", registeredRole);
    localStorage.setItem("coach_demo_mode", "false");
    await loadCoachData({ forceApi: true });
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
    status: recording?.status === "rejected" ? "needs_revision" : "approved",
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

  const payload = { status, score, feedback };
  let reviewResult = null;

  if (!state.demoMode) {
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
  persistDemoSnapshot();
  state.selectedRecordingId = null;
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
  if (state.recordingStatusFilter === "all") {
    return state.recordings;
  }

  return state.recordings.filter(
    (recording) => recording.status === state.recordingStatusFilter,
  );
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
    if (state.demoMode) {
      const saved = {
        id:
          editingId ||
          Math.max(0, ...state.adminUsers.map((user) => Number(user.id) || 0)) + 1,
        ...payload,
        personalization_completed: payload.role !== "athlete",
        created_at: new Date().toISOString(),
      };
      delete saved.password;
      delete saved.password_confirmation;
      state.adminUsers = editingId
        ? state.adminUsers.map((user) => (Number(user.id) === Number(editingId) ? saved : user))
        : [...state.adminUsers, saved];
      state.loading = false;
      resetAdminUserForm();
      persistDemoSnapshot();
      return;
    }

    await request(editingId ? `/admin/users/${editingId}` : "/admin/users", {
      method: editingId ? "PUT" : "POST",
      body: JSON.stringify(payload),
    });

    state.editingAdminUserId = null;
    state.adminUserForm = emptyAdminUserForm();
    await loadCoachData({ forceApi: true });
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
    if (state.demoMode) {
      state.adminUsers = state.adminUsers.filter((item) => Number(item.id) !== Number(id));
      state.loading = false;
      persistDemoSnapshot();
      render();
      return;
    }

    await request(`/admin/users/${id}`, { method: "DELETE" });
    await loadCoachData({ forceApi: true });
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
    if (state.demoMode) {
      const saved = {
        id:
          editingId ||
          Math.max(0, ...state.adminPrograms.map((program) => Number(program.id) || 0)) + 1,
        ...payload,
        exercise_count:
          state.adminPrograms.find((program) => Number(program.id) === Number(editingId))
            ?.exercise_count || 0,
        exercises:
          state.adminPrograms.find((program) => Number(program.id) === Number(editingId))
            ?.exercises || [],
      };
      state.adminPrograms = editingId
        ? state.adminPrograms.map((program) =>
            Number(program.id) === Number(editingId) ? saved : program,
          )
        : [...state.adminPrograms, saved];
      state.selectedProgramId = saved.id;
      state.loading = false;
      resetAdminProgramForm();
      persistDemoSnapshot();
      return;
    }

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
    await loadCoachData({ forceApi: true });
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
    if (state.demoMode) {
      state.adminPrograms = state.adminPrograms.filter(
        (item) => Number(item.id) !== Number(id),
      );
      if (Number(state.selectedProgramId) === Number(id)) {
        state.selectedProgramId = null;
      }
      state.loading = false;
      persistDemoSnapshot();
      render();
      return;
    }

    await request(`/admin/programs/${id}`, { method: "DELETE" });
    if (Number(state.selectedProgramId) === Number(id)) {
      state.selectedProgramId = null;
    }
    await loadCoachData({ forceApi: true });
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

  state.loading = true;
  state.error = "";
  render();

  try {
    if (state.demoMode) {
      const saved = {
        workout_exercise_id:
          editingId ||
          Math.max(
            0,
            ...(program.exercises || []).map((exercise) => Number(exercise.workout_exercise_id) || 0),
          ) + 1,
        exercise_id:
          Math.max(0, ...(program.exercises || []).map((exercise) => Number(exercise.exercise_id) || 0)) +
          1,
        ...payload,
      };
      state.adminPrograms = state.adminPrograms.map((item) => {
        if (Number(item.id) !== Number(program.id)) return item;
        const exercises = editingId
          ? (item.exercises || []).map((exercise) =>
              Number(exercise.workout_exercise_id) === Number(editingId) ? saved : exercise,
            )
          : [...(item.exercises || []), saved];
        return { ...item, exercises, exercise_count: exercises.length };
      });
      syncProgramVideoSnapshot();
      state.loading = false;
      resetProgramExerciseForm();
      persistDemoSnapshot();
      return;
    }

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
    await loadCoachData({ forceApi: true });
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
    if (state.demoMode) {
      state.adminPrograms = state.adminPrograms.map((item) => {
        if (Number(item.id) !== Number(program.id)) return item;
        const exercises = (item.exercises || []).filter(
          (exercise) => Number(exercise.workout_exercise_id) !== Number(id),
        );
        return { ...item, exercises, exercise_count: exercises.length };
      });
      syncProgramVideoSnapshot();
      state.loading = false;
      persistDemoSnapshot();
      render();
      return;
    }

    await request(`/admin/program-exercises/${id}`, { method: "DELETE" });
    await loadCoachData({ forceApi: true });
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

function syncProgramVideoSnapshot() {
  state.adminVideos = programVideoRowsFromPrograms();
}

function updateProgramExerciseVideo(workoutExerciseId, videoUrl) {
  state.adminPrograms = state.adminPrograms.map((program) => {
    const exercises = (program.exercises || []).map((exercise) =>
      Number(exercise.workout_exercise_id) === Number(workoutExerciseId)
        ? { ...exercise, video_url: videoUrl || "" }
        : exercise,
    );

    return { ...program, exercises };
  });
  syncProgramVideoSnapshot();
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
  render();
}

function adminVideoPayload(form) {
  return {
    workout_exercise_id: Number(form.get("workout_exercise_id") || 0),
    video_url: String(form.get("video_url") || "").trim(),
  };
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

  if (!payload.video_url) {
    state.error = "Video URL wajib diisi.";
    render();
    return;
  }

  state.loading = true;
  state.error = "";
  render();

  try {
    if (state.demoMode) {
      updateProgramExerciseVideo(payload.workout_exercise_id, payload.video_url);
      state.loading = false;
      resetAdminVideoForm();
      persistDemoSnapshot();
      return;
    }

    await request(state.editingAdminVideoId ? `/admin/videos/${editingId}` : "/admin/videos", {
      method: state.editingAdminVideoId ? "PUT" : "POST",
      body: JSON.stringify(payload),
    });

    state.editingAdminVideoId = null;
    state.adminVideoForm = emptyAdminVideoForm();
    await loadCoachData({ forceApi: true });
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
    if (state.demoMode) {
      updateProgramExerciseVideo(id, "");
      state.loading = false;
      persistDemoSnapshot();
      render();
      return;
    }

    await request(`/admin/videos/${id}`, { method: "DELETE" });
    await loadCoachData({ forceApi: true });
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

  return Array.from({ length: 14 }, (_, index) => {
    const dayNumber = index + 1;
    const dayRecordings = recordings
      .filter((item) => Number(item.day_number) === dayNumber)
      .sort((a, b) => new Date(b.uploaded_at || 0) - new Date(a.uploaded_at || 0));
    const recording = dayRecordings[0];

    if (!recording) {
      return {
        dayNumber,
        recordingId: null,
        status: "not_started",
        score: null,
        label: "Belum latihan",
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
      };
    }

    return {
      dayNumber,
      recordingId: recording.id,
      status: "pending",
      score: null,
      label: "Menunggu review",
      recordingCount: dayRecordings.length,
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
          ["admin-users", "U", "User"],
          ["admin-programs", "P", "Program"],
          ["admin-videos", "V", "Video"],
          ["settings", "S", "API"],
        ]
      : [
          ["dashboard", "D", "Dashboard"],
          ["athletes", "A", "Atlet"],
          ["recordings", "R", "Review"],
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
          <div class="api-label">${state.demoMode ? "Mode Demo" : "API Aktif"}</div>
          <div class="api-value">${escapeHtml(state.apiBaseUrl)}</div>
        </div>
        <button class="btn ghost" id="logout-button" type="button">Keluar</button>
      </div>
    </aside>
  `;
}

function renderMainView() {
  const hasAdminData =
    state.adminUsers.length || state.adminPrograms.length || state.adminVideos.length;

  if (state.loading && state.userRole === "admin" && !hasAdminData) {
    return `<div class="empty">Memuat data admin...</div>`;
  }

  if (state.loading && state.userRole !== "admin" && !state.dashboard) {
    return `<div class="empty">Memuat data coach...</div>`;
  }

  if (state.view === "athletes") return renderAthletes();
  if (state.view === "recordings") return renderRecordings();
  if (state.view === "admin-users" || state.view === "admin") return renderAdminUsers();
  if (state.view === "admin-programs") return renderAdminPrograms();
  if (state.view === "admin-videos") return renderAdminVideos();
  if (state.view === "settings") return renderSettings();
  return renderDashboard();
}

function renderRefreshButton() {
  return `<button class="btn ghost" id="refresh-button" type="button">Muat Ulang</button>`;
}

function renderDashboard() {
  const dashboard = state.dashboard || demoData.dashboard;
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
      ${renderKpi("Atlet Aktif", dashboard.active_athletes, "Aktif latihan beberapa hari terakhir")}
      ${renderKpi("Perlu Review", dashboard.pending_reviews, "Video menunggu coach")}
      ${renderKpi("Avg Performance", `${dashboard.average_performance}%`, "Berdasarkan validasi coach")}
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
  const days = workoutDaysForAthlete(athlete);

  return `
    ${renderTopbar(athlete.name, "Detail progress atlet berdasarkan latihan yang dikirim dan review coach.", [
      `<button class="btn ghost" id="back-athletes" type="button">Kembali</button>`,
    ])}
    <section class="grid kpi-grid">
      ${renderKpi("Consistency", `${athlete.consistency_progress || 0}%`, "Otomatis dari aktivitas latihan")}
      ${renderKpi("Performance", `${athlete.performance_progress || 0}%`, "Dari validasi coach")}
      ${renderKpi("Pending Review", athlete.pending_reviews || 0, "Video belum divalidasi")}
      ${renderKpi("Level", athlete.training_level || "-", "Program aktif atlet")}
    </section>
    <section class="card pad" style="margin-top: 16px">
      <h2 class="card-title">Progress Day 1-14</h2>
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
          ${renderProfileLine("Status", statusLabel(athlete.status))}
          ${renderProfileLine("Terakhir latihan", formatDateTime(athlete.last_activity_at))}
          ${renderProfileLine("Catatan", "Performance progress hanya berubah setelah coach memberi review.")}
        </div>
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
          <input class="input" id="video-url" name="video_url" value="${escapeAttr(form.video_url)}" placeholder="https://... atau /storage/..." required />
        </div>
        ${
          form.video_url
            ? `<div class="notice">Preview aktif: <a class="table-link" href="${escapeAttr(videoPlayerUrl(resolveBackendAssetUrl(form.video_url), { title: "Preview Video Latihan", subtitle: "Video yang sedang diedit", view: "admin-videos" }))}" target="_blank" rel="noreferrer">Buka video</a></div>`
            : `<div class="notice">Video ini dipakai tombol preview/play di workout list aplikasi atlet.</div>`
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
          <button class="btn ghost" id="demo-mode-button" type="button">Mode Demo</button>
          <button class="btn danger" id="reset-demo-button" type="button">Reset Demo</button>
        </div>
        <div class="notice">
          Web coach tersambung ke endpoint aplikasi: /coach/dashboard, /coach/athletes, /coach/recordings, dan /coach/recordings/{id}/review.
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
      <td>${renderProgress(athlete.consistency_progress || 0, "Consistency")}</td>
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
      <td>${videoUrl ? `<a class="table-link" href="${escapeAttr(playerUrl)}" target="_blank" rel="noreferrer">Buka</a>` : `<span class="muted small">Belum ada</span>`}</td>
      <td>
        <div class="row-actions">
          <button class="btn ghost" data-video-edit="${escapeAttr(id)}" type="button">Edit</button>
          <button class="btn danger" data-video-delete="${escapeAttr(id)}" type="button" ${videoUrl ? "" : "disabled"}>Hapus</button>
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
          <span class="muted small">ID ${escapeHtml(recording.user_id || "-")}</span>
        </div>
      </td>
      <td>Day ${escapeHtml(recording.day_number || "-")}</td>
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
          <div class="muted small">Day ${escapeHtml(recording.day_number || "-")} - ${formatDateTime(recording.uploaded_at)}</div>
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
              <select class="select" id="review-status" name="status">
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
              <textarea class="textarea" id="review-feedback" name="feedback" placeholder="Contoh: landing sudah stabil, tapi start sprint perlu lebih eksplosif.">${escapeHtml(state.reviewDraft.feedback)}</textarea>
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
    ?.addEventListener("click", () => loadCoachData({ forceApi: !state.demoMode }));
  document
    .querySelector("#fetch-api-button")
    ?.addEventListener("click", () => loadCoachData({ forceApi: true }));
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
  document.querySelectorAll("[data-video-program-detail]").forEach((button) => {
    button.addEventListener("click", () =>
      selectAdminVideoProgram(button.dataset.videoProgramDetail),
    );
  });

  document.querySelector("#athlete-search")?.addEventListener("input", (event) => {
    state.search = event.target.value;
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

  document.querySelector("#demo-mode-button")?.addEventListener("click", () => {
    state.demoMode = true;
    localStorage.setItem("coach_demo_mode", "true");
    loadCoachData();
  });
  document
    .querySelector("#reset-demo-button")
    ?.addEventListener("click", resetDemoSnapshot);
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

    window.location.href = webAppUrl(state.userRole === "admin" ? "admin-videos" : "recordings");
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

function stringOrNull(value) {
  const text = String(value ?? "").trim();
  return text === "" ? null : text;
}

function isViewAllowedForRole(view, role) {
  const adminViews = ["admin-users", "admin-programs", "admin-videos", "settings"];
  const coachViews = ["dashboard", "athletes", "recordings", "settings"];

  return role === "admin" ? adminViews.includes(view) : coachViews.includes(view);
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

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
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
