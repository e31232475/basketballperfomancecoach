<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\WorkoutController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CoachController;
use App\Http\Controllers\AdminController;

Route::get('/next-day/{user_id}', [WorkoutController::class, 'nextDay']);
Route::get('/progress', [WorkoutController::class, 'saveProgress']);
Route::get('/reset-day/{user_id}', [WorkoutController::class, 'resetDay']);
Route::get('/complete/{user_id}', [WorkoutController::class, 'completeWorkout']);
Route::get('/history/{user_id}', [WorkoutController::class, 'history']);
Route::post('/exercise-progress', [WorkoutController::class, 'saveExerciseProgress']);
Route::get('/exercise-progress/{user_id}/{workout_id}', [WorkoutController::class, 'getExerciseProgress']); 
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/firebase-login', [AuthController::class, 'firebaseLogin']);

Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::get('/user/{id}', [AuthController::class, 'user']);
Route::post('/personalization', [AuthController::class, 'personalization']);
Route::get('/profile/{id}', [AuthController::class, 'profile']);
Route::get(
    '/workout-list/{user_id}',
    [WorkoutController::class, 'workoutList']
);
Route::post(
    '/complete-workout/{user_id}/{day_number}',
    [WorkoutController::class, 'completeWorkout']
);
Route::get('/workout/{day}', [WorkoutController::class, 'getWorkout']);
Route::post('/performance-log', [WorkoutController::class, 'performanceLog']);
Route::post('/workout-recordings', [WorkoutController::class, 'storeWorkoutRecording']);
Route::get('/performance-summary/{user_id}', [WorkoutController::class, 'performanceSummary']);
Route::get('/progress/{user_id}', [WorkoutController::class, 'progress']);

Route::middleware('auth:sanctum')->prefix('coach')->group(function () {
    Route::get('/dashboard', [CoachController::class, 'dashboard']);
    Route::get('/athletes', [CoachController::class, 'athletes']);
    Route::get('/athletes/{user_id}', [CoachController::class, 'athlete']);
    Route::get('/recordings', [CoachController::class, 'recordings']);
    Route::post('/recordings/{recording_id}/review', [CoachController::class, 'review']);
});

Route::middleware('auth:sanctum')->prefix('admin')->group(function () {
    Route::get('/users', [AdminController::class, 'index']);
    Route::post('/users', [AdminController::class, 'store']);
    Route::get('/users/{user_id}', [AdminController::class, 'show']);
    Route::put('/users/{user_id}', [AdminController::class, 'update']);
    Route::patch('/users/{user_id}', [AdminController::class, 'update']);
    Route::delete('/users/{user_id}', [AdminController::class, 'destroy']);

    Route::get('/programs', [AdminController::class, 'programs']);
    Route::post('/programs', [AdminController::class, 'storeProgram']);
    Route::get('/programs/{program_id}', [AdminController::class, 'showProgram']);
    Route::put('/programs/{program_id}', [AdminController::class, 'updateProgram']);
    Route::patch('/programs/{program_id}', [AdminController::class, 'updateProgram']);
    Route::delete('/programs/{program_id}', [AdminController::class, 'destroyProgram']);
    Route::post('/programs/{program_id}/exercises', [AdminController::class, 'storeProgramExercise']);
    Route::put('/program-exercises/{workout_exercise_id}', [AdminController::class, 'updateProgramExercise']);
    Route::patch('/program-exercises/{workout_exercise_id}', [AdminController::class, 'updateProgramExercise']);
    Route::delete('/program-exercises/{workout_exercise_id}', [AdminController::class, 'destroyProgramExercise']);

    Route::get('/videos', [AdminController::class, 'videos']);
    Route::post('/videos', [AdminController::class, 'storeVideo']);
    Route::get('/videos/{workout_exercise_id}', [AdminController::class, 'showVideo']);
    Route::put('/videos/{workout_exercise_id}', [AdminController::class, 'updateVideo']);
    Route::patch('/videos/{workout_exercise_id}', [AdminController::class, 'updateVideo']);
    Route::delete('/videos/{workout_exercise_id}', [AdminController::class, 'destroyVideo']);
});
