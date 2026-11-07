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
        Schema::table('players', function (Blueprint $table) {
            $table->string('recovery_code', 24)->nullable()->unique()->index()->after('normalized_nickname');
            $table->longText('progress_payload')->nullable()->after('league_group_id');
            $table->timestamp('progress_synced_at')->nullable()->after('progress_payload');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('players', function (Blueprint $table) {
            $table->dropColumn(['recovery_code', 'progress_payload', 'progress_synced_at']);
        });
    }
};

