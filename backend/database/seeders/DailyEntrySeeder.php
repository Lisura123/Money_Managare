<?php

namespace Database\Seeders;

use App\Models\CardAccount;
use App\Models\DailyCardEntry;
use App\Models\DailyCashEntry;
use App\Models\Showroom;
use App\Models\User;
use Illuminate\Database\Seeder;

class DailyEntrySeeder extends Seeder
{
    public function run(): void
    {
        $staffUsers = User::where('role', 'staff')->get();

        // 2 weeks of daily entries
        for ($day = 13; $day >= 0; $day--) {
            $date = now()->subDays($day)->format('Y-m-d');

            foreach ($staffUsers as $staff) {
                // Cash entry — Main Account
                DailyCashEntry::create([
                    'showroom_id'       => $staff->showroom_id,
                    'user_id'           => $staff->id,
                    'entry_date'        => $date,
                    'cash_amount'       => rand(500, 5000) + (rand(0, 99) / 100),
                    'notes'             => 'Seeded main entry for ' . $date,
                    'is_locked'         => $day > 1,
                    'cash_account_type' => 'main',
                ]);

                // Cash entry — Mano's Account
                DailyCashEntry::create([
                    'showroom_id'       => $staff->showroom_id,
                    'user_id'           => $staff->id,
                    'entry_date'        => $date,
                    'cash_amount'       => rand(200, 2000) + (rand(0, 99) / 100),
                    'notes'             => "Seeded mano entry for " . $date,
                    'is_locked'         => $day > 1,
                    'cash_account_type' => 'mano',
                ]);

                // Card entry — pick first active card account for this showroom
                $cardAccount = CardAccount::where('showroom_id', $staff->showroom_id)
                    ->where('is_active', true)
                    ->first();

                if ($cardAccount) {
                    $amount = rand(200, 3000) + (rand(0, 99) / 100);
                    DailyCardEntry::create([
                        'showroom_id'     => $staff->showroom_id,
                        'user_id'         => $staff->id,
                        'card_account_id' => $cardAccount->id,
                        'entry_date'      => $date,
                        'amount'          => $amount,
                        'notes'           => 'Seeded card entry for ' . $date,
                        'is_locked'       => $day > 1,
                    ]);
                }
            }
        }
    }
}
