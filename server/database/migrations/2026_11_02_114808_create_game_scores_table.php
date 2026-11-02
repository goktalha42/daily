<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('game_scores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('player_id')->constrained('players')->onDelete('cascade');
            $table->string('game_type', 32)->index();
            $table->string('date_id', 16)->index();
            $table->string('difficulty', 32)->default('default');
            $table->integer('score');
            $table->integer('duration_ms');
            $table->integer('move_count')->default(0);
            $table->timestamp('completed_at')->index();
            $table->timestamps();

            $table->unique(['player_id', 'game_type', 'date_id', 'difficulty'], 'player_game_date_diff_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('game_scores');
    }
};
