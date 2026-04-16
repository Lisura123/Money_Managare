<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('card_accounts', function (Blueprint $table) {
            $table->decimal('opening_balance', 12, 2)->default(0)->after('current_balance');
        });

        // Backfill: opening_balance = current_balance minus all mutations already applied
        // (entries and self-transactions are applied; adjustments are NOT applied to current_balance yet)
        DB::statement("
            UPDATE card_accounts ca
            SET ca.opening_balance = (
                ca.current_balance
                - COALESCE((SELECT SUM(dce.amount) FROM daily_card_entries dce WHERE dce.card_account_id = ca.id), 0)
                - COALESCE((SELECT SUM(st.amount)  FROM self_transactions st  WHERE st.to_card_account_id   = ca.id), 0)
                + COALESCE((SELECT SUM(st.amount)  FROM self_transactions st  WHERE st.from_card_account_id = ca.id), 0)
            )
        ");
    }

    public function down(): void
    {
        Schema::table('card_accounts', function (Blueprint $table) {
            $table->dropColumn('opening_balance');
        });
    }
};
