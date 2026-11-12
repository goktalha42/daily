<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_puzzles', function (Blueprint $table) {
            $table->id();
            $table->string('date_id', 10)->index();
            $table->string('game_type', 32); // queens, pinpoint, crossclimb, tango, zip_path, patches
            $table->string('difficulty', 32)->default('default'); // default | kolay | zor | master
            $table->longText('payload');
            $table->boolean('is_special')->default(false);
            $table->string('special_note', 255)->nullable();
            $table->string('source', 16)->default('auto'); // auto | admin
            $table->timestamps();

            $table->unique(['date_id', 'game_type', 'difficulty']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_puzzles');
    }
};

