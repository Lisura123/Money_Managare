<?php

namespace Database\Seeders;

use App\Models\CardAccount;
use App\Models\DailyCashEntry;
use App\Models\Showroom;
use App\Models\User;
use App\Models\BalanceUpdate;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Replaces the showroom + bank-account list with the real CLK data and seeds
 * the current opening balances, while preserving all existing entries and
 * transaction history.
 *
 * Balance model:
 *   - Card accounts store their balance directly in `current_balance`
 *     (and `opening_balance`, used when the balance is recalculated from the
 *     full transaction history).
 *   - Main-cash has no balance column; it is computed by summing each
 *     showroom's `main` daily_cash_entries (+ adjustments / transfers). The
 *     starting balance is therefore seeded as a single, locked "Opening
 *     balance" cash entry dated on OPENING_DATE.
 *
 * Old showrooms/accounts not in the new list are DEACTIVATED (is_active =
 * false) rather than deleted, so historical rows that reference them are
 * never destroyed.
 *
 * Run on the server with:
 *   php artisan db:seed --class=LiveShowroomSeeder --force
 */
class LiveShowroomSeeder extends Seeder
{
    /** Date used for the seeded opening-balance cash entries. */
    private const OPENING_DATE = '2026-06-11';

    public function run(): void
    {
        // showroom => ['main_cash' => float, 'accounts' => [[bank, last_four, balance], ...]]
        $data = [
            'CAMERALK (PVT) LTD' => [
                'main_cash' => 3221695.00,
                'accounts'  => [
                    ['Sampath', '3205', 448719.17],
                    ['HNB', '5456', -6600661.97],
                    ['HNB', '2568', 18827.39],
                    ['Peoples Bank', '3109', 69433.37],
                    ['Union Bank (USD)', '1071', 403394.95],
                    ['Union Bank (LKR)', '4808', 47936.00],
                    ['NTB', '3370', 158186.41],
                    ['Sampath', '7954', 97030.09],
                    ['Sampath', '7946', 590446.06],
                    ['HNB', '9453', 1360458.44],
                    ['HNB', '5294', 960000.00],
                    ['Sampath', '7461', 241589.27],
                ],
            ],
            'SONY ASIA PASIFIC (PVT) LTD' => [
                'main_cash' => 5111300.00,
                'accounts'  => [
                    ['Sampath', '3206', 1515191.41],
                    ['Commercial', '0538', 2768182.64],
                    ['HNB', '8553', 19650.00],
                    ['NTB', '2464', 124874.15],
                    ['Sampath', '1244', 411406.75],
                    ['Sampath', '9574', 1184022.07],
                ],
            ],
            'KOSMISCH GLOBAL (PVT) LTD' => [
                'main_cash' => 163500.00,
                'accounts'  => [
                    ['Sampath', '9258', 23703.00],
                    ['Sampath', '4779', 20018.35],
                    ['Sampath', '0429', 1923762.09],
                    ['NTB', '4062', 166063.03],
                    ['HNB', '8696', 25000.00],
                ],
            ],
            'CLK KANDY (PVT) LTD' => [
                'main_cash' => 1354400.00,
                'accounts'  => [
                    ['DFCC', '9037', 1013456.26],
                    ['HNB', '8571', 19300.00],
                    ['NTB', '2488', 58780.15],
                    ['DFCC', '2427', 24775.27],
                ],
            ],
            'CAMERA DOT LK (PVT) LTD' => [
                'main_cash' => 107300.00,
                'accounts'  => [
                    ['Pan Asia Bank', '0810', 421496.64],
                    ['NTB', '2419', 15931.95],
                    ['Pan Asia Bank', '3104', 32724.24],
                ],
            ],
            'CLK PHOTOGRAPHY (PVT) LTD' => [
                'main_cash' => 268300.00,
                'accounts'  => [
                    ['Sampath', '9876', 214463.16],
                    ['NTB', '3751', 74545.00],
                ],
            ],
            'NM CREATION' => [
                'main_cash' => 110900.00,
                'accounts'  => [
                    ['Sampath', '0135', 314022.36],
                    ['NTB', '3942', 165683.00],
                ],
            ],
            'MAGNUS INTERNATIONAL (PVT) LTD' => [
                'main_cash' => 0.00,
                'accounts'  => [
                    ['Sampath', '9663', 538607.40],
                    ['Sampath', '9566', 438194.79],
                ],
            ],
        ];

        $keepNames = array_keys($data);

        // A user is required to own the opening cash entries.
        $openingUserId = User::where('role', 'admin')->orderBy('id')->value('id')
            ?? User::orderBy('id')->value('id');

        DB::transaction(function () use ($data, $keepNames, $openingUserId) {
            // 1. Deactivate old showrooms (and all their bank accounts) not in
            //    the new list. History rows are preserved.
            $oldShowrooms = Showroom::whereNotIn('name', $keepNames)->get();
            foreach ($oldShowrooms as $old) {
                $old->cardAccounts()->update(['is_active' => false]);
                $old->update(['is_active' => false]);
            }

            // 2. Upsert the new showrooms, their bank accounts and balances.
            foreach ($data as $showroomName => $config) {
                $showroom = Showroom::firstOrCreate(
                    ['name' => $showroomName],
                    ['location' => '', 'is_active' => true],
                );

                // Make sure a previously-deactivated showroom is re-enabled.
                if (! $showroom->is_active) {
                    $showroom->update(['is_active' => true]);
                }

                $accounts        = $config['accounts'];
                $wantedLastFours = array_map(fn ($a) => $a[1], $accounts);

                // Deactivate any bank accounts on this showroom no longer listed.
                $showroom->cardAccounts()
                    ->whereNotIn('last_four', $wantedLastFours)
                    ->update(['is_active' => false]);

                foreach ($accounts as [$bankName, $lastFour, $balance]) {
                    CardAccount::updateOrCreate(
                        [
                            'showroom_id' => $showroom->id,
                            'bank_name'   => $bankName,
                            'last_four'   => $lastFour,
                        ],
                        [
                            'current_balance'      => $balance,
                            'opening_balance'      => $balance,
                            'opening_balance_date' => self::OPENING_DATE,
                            'is_active'            => true,
                        ],
                    );

                    // Record card opening balance in Balance Updates so it
                    // appears under Records → Balance Updates on OPENING_DATE.
                    if ($openingUserId !== null && $balance != 0) {
                        $cardId = CardAccount::where('showroom_id', $showroom->id)
                            ->where('bank_name', $bankName)
                            ->where('last_four', $lastFour)
                            ->value('id');
                        $label = trim($bankName . ' •••• ' . $lastFour);
                        $existing = DB::table('balance_updates')
                            ->where('showroom_id', $showroom->id)
                            ->where('account_type', 'bank')
                            ->where('account_label', $label)
                            ->where('reason', 'Opening balance')
                            ->first();
                        $buData = [
                            'showroom_id'     => $showroom->id,
                            'account_type'    => 'bank',
                            'card_account_id' => $cardId,
                            'account_label'   => $label,
                            'previous_amount' => 0,
                            'new_amount'      => $balance,
                            'change_amount'   => $balance,
                            'reason'          => 'Opening balance',
                            'user_id'         => $openingUserId,
                            'created_at'      => self::OPENING_DATE . ' 00:00:00',
                            'updated_at'      => self::OPENING_DATE . ' 00:00:00',
                        ];
                        if ($existing) {
                            DB::table('balance_updates')->where('id', $existing->id)->update($buData);
                        } else {
                            DB::table('balance_updates')->insert($buData);
                        }
                    }
                }

                // 3. Seed the main-cash opening balance as one locked entry.
                // Remove any previously-seeded opening entry (old date) to avoid
                // duplicate rows when OPENING_DATE is changed.
                if ($openingUserId !== null) {
                    DailyCashEntry::where('showroom_id', $showroom->id)
                        ->where('cash_account_type', 'main')
                        ->where('notes', 'Opening balance')
                        ->where('entry_date', '!=', self::OPENING_DATE)
                        ->delete();

                    DailyCashEntry::updateOrCreate(
                        [
                            'showroom_id'       => $showroom->id,
                            'entry_date'        => self::OPENING_DATE,
                            'cash_account_type' => 'main',
                            'notes'             => 'Opening balance',
                        ],
                        [
                            'user_id'     => $openingUserId,
                            'cash_amount' => $config['main_cash'],
                            'is_locked'   => true,
                        ],
                    );

                    // Record main cash opening balance in Balance Updates.
                    if ($config['main_cash'] != 0) {
                        $existing = DB::table('balance_updates')
                            ->where('showroom_id', $showroom->id)
                            ->where('account_type', 'main_cash')
                            ->where('reason', 'Opening balance')
                            ->first();
                        $buData = [
                            'showroom_id'     => $showroom->id,
                            'account_type'    => 'main_cash',
                            'card_account_id' => null,
                            'account_label'   => 'Main Cash',
                            'previous_amount' => 0,
                            'new_amount'      => $config['main_cash'],
                            'change_amount'   => $config['main_cash'],
                            'reason'          => 'Opening balance',
                            'user_id'         => $openingUserId,
                            'created_at'      => self::OPENING_DATE . ' 00:00:00',
                            'updated_at'      => self::OPENING_DATE . ' 00:00:00',
                        ];
                        if ($existing) {
                            DB::table('balance_updates')->where('id', $existing->id)->update($buData);
                        } else {
                            DB::table('balance_updates')->insert($buData);
                        }
                    }
                }
            }
        });
    }
}
