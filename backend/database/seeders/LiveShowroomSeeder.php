<?php

namespace Database\Seeders;

use App\Models\CardAccount;
use App\Models\Showroom;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Replaces the showroom + bank-account list with the real CLK data while
 * preserving all existing entries and transaction history.
 *
 * Because daily_cash_entries, daily_card_entries, self_transactions and
 * adjustments all cascade-delete from showrooms/card_accounts, the old
 * records are DEACTIVATED (is_active = false) rather than deleted. This
 * removes them from every active list in the app without destroying the
 * historical rows that reference them.
 *
 * Run on the server with:
 *   php artisan db:seed --class=LiveShowroomSeeder --force
 */
class LiveShowroomSeeder extends Seeder
{
    public function run(): void
    {
        $accountsByShowroom = [
            'CAMERALK (PVT) LTD' => [
                ['Sampath', '3205'],
                ['HNB', '5456'],
                ['HNB', '2568'],
                ['Peoples Bank', '3109'],
                ['Union Bank (USD)', '1071'],
                ['Union Bank (LKR)', '4808'],
                ['NTB', '3370'],
                ['Sampath', '7954'],
                ['Sampath', '7946'],
                ['HNB', '9453'],
                ['HNB', '5294'],
                ['Sampath', '7461'],
            ],
            'SONY ASIA PASIFIC (PVT) LTD' => [
                ['Sampath', '3206'],
                ['Commercial', '0538'],
                ['HNB', '8553'],
                ['NTB', '2464'],
                ['Sampath', '1244'],
                ['Sampath', '9574'],
            ],
            'KOSMISCH GLOBAL (PVT) LTD' => [
                ['Sampath', '9258'],
                ['Sampath', '4779'],
                ['Sampath', '0429'],
                ['NTB', '4062'],
                ['HNB', '8696'],
            ],
            'CLK KANDY (PVT) LTD' => [
                ['DFCC', '9037'],
                ['HNB', '8571'],
                ['NTB', '2488'],
                ['DFCC', '2427'],
            ],
            'CAMERA DOT LK (PVT) LTD' => [
                ['Pan Asia Bank', '0810'],
                ['NTB', '2419'],
                ['Pan Asia Bank', '3104'],
            ],
            'CLK PHOTOGRAPHY (PVT) LTD' => [
                ['Sampath', '9876'],
                ['NTB', '3751'],
            ],
            'NM CREATION' => [
                ['Sampath', '0135'],
                ['NTB', '3942'],
            ],
            'MAGNUS INTERNATIONAL (PVT) LTD' => [
                ['Sampath', '9663'],
                ['Sampath', '9566'],
            ],
        ];

        $keepNames = array_keys($accountsByShowroom);

        DB::transaction(function () use ($accountsByShowroom, $keepNames) {
            // 1. Deactivate old showrooms (and all their bank accounts) that are
            //    not part of the new list. History rows are preserved.
            $oldShowrooms = Showroom::whereNotIn('name', $keepNames)->get();
            foreach ($oldShowrooms as $old) {
                $old->cardAccounts()->update(['is_active' => false]);
                $old->update(['is_active' => false]);
            }

            // 2. Upsert the new showrooms and their bank accounts.
            foreach ($accountsByShowroom as $showroomName => $accounts) {
                $showroom = Showroom::firstOrCreate(
                    ['name' => $showroomName],
                    ['location' => '', 'is_active' => true],
                );

                // Make sure a previously-deactivated showroom is re-enabled.
                if (! $showroom->is_active) {
                    $showroom->update(['is_active' => true]);
                }

                $wantedLastFours = array_map(fn ($a) => $a[1], $accounts);

                // Deactivate any bank accounts on this showroom that are no
                // longer in the provided list.
                $showroom->cardAccounts()
                    ->whereNotIn('last_four', $wantedLastFours)
                    ->update(['is_active' => false]);

                foreach ($accounts as [$bankName, $lastFour]) {
                    $account = CardAccount::firstOrCreate(
                        [
                            'showroom_id' => $showroom->id,
                            'bank_name'   => $bankName,
                            'last_four'   => $lastFour,
                        ],
                        [
                            'current_balance' => 0.00,
                            'opening_balance' => 0.00,
                            'is_active'       => true,
                        ],
                    );

                    if (! $account->is_active) {
                        $account->update(['is_active' => true]);
                    }
                }
            }
        });
    }
}
