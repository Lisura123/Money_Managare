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
    /** Snapshot dates: opening balances (set 1), then updated balances (set 2 / current). */
    private const OPENING_DATE = '2026-06-11';
    private const UPDATE_DATE  = '2026-06-15';

    public function run(): void
    {
        // showroom => [
        //   'main_open' => float (Main Cash on OPENING_DATE),
        //   'main_now'  => float (Main Cash on UPDATE_DATE / current),
        //   'accounts'  => [[bank, last_four, open_balance, now_balance], ...],
        // ]
        $data = [
            'CAMERALK (PVT) LTD' => [
                'main_open' => 3221695.00,
                'main_now'  => 5664300.00,
                'accounts'  => [
                    ['Sampath', '3205', 448719.17, 2343324.17],
                    ['HNB', '5456', -6600661.97, 3076733.50],
                    ['HNB', '2568', 18827.39, 18827.39],
                    ['Peoples Bank', '3109', 69433.37, 69433.37],
                    ['Union Bank (USD)', '1071', 403394.95, 403394.95],
                    ['Union Bank (LKR)', '4808', 47936.00, 47936.00],
                    ['NTB', '3370', 158186.41, 158186.41],
                    ['Sampath', '7954', 97030.09, 97030.09],
                    ['Sampath', '7946', 590446.06, 1006946.06],
                    ['HNB', '9453', 1360458.44, 1360458.44],
                    ['HNB', '5294', 960000.00, 960000.00],
                    ['Sampath', '7461', 241589.27, 241589.27],
                ],
            ],
            'SONY ASIA PASIFIC (PVT) LTD' => [
                'main_open' => 5111300.00,
                'main_now'  => 9681095.00,
                'accounts'  => [
                    ['Sampath', '3206', 1515191.41, 2367711.41],
                    ['Commercial', '0538', 2768182.64, 2338682.64],
                    ['HNB', '8553', 19650.00, 19650.00],
                    ['NTB', '2464', 124874.15, 124874.15],
                    ['Sampath', '1244', 411406.75, 1482906.75],
                    ['Sampath', '9574', 1184022.07, 774922.07],
                ],
            ],
            'KOSMISCH GLOBAL (PVT) LTD' => [
                'main_open' => 163500.00,
                'main_now'  => 1667600.00,
                'accounts'  => [
                    ['Sampath', '9258', 23703.00, 23703.00],
                    ['Sampath', '4779', 20018.35, 20018.35],
                    ['Sampath', '0429', 1923762.09, 3513122.09],
                    ['NTB', '4062', 166063.03, 577463.03],
                    ['HNB', '8696', 25000.00, 25000.00],
                ],
            ],
            'CLK KANDY (PVT) LTD' => [
                'main_open' => 1354400.00,
                'main_now'  => 1206700.00,
                'accounts'  => [
                    ['DFCC', '9037', 1013456.26, 2766976.26],
                    ['HNB', '8571', 19300.00, 19300.00],
                    ['NTB', '2488', 58780.15, 257180.15],
                    ['DFCC', '2427', 24775.27, 24775.27],
                ],
            ],
            'CAMERA DOT LK (PVT) LTD' => [
                'main_open' => 107300.00,
                'main_now'  => 301100.00,
                'accounts'  => [
                    ['Pan Asia Bank', '0810', 421496.64, 620046.64],
                    ['NTB', '2419', 15931.95, 15931.95],
                    ['Pan Asia Bank', '3104', 32724.24, 32724.24],
                ],
            ],
            'CLK PHOTOGRAPHY (PVT) LTD' => [
                'main_open' => 268300.00,
                'main_now'  => 1433500.00,
                'accounts'  => [
                    ['Sampath', '9876', 214463.16, 725963.16],
                    ['NTB', '3751', 74545.00, 74545.00],
                ],
            ],
            'NM CREATION' => [
                'main_open' => 110900.00,
                'main_now'  => 315300.00,
                'accounts'  => [
                    ['Sampath', '0135', 314022.36, 391822.36],
                    ['NTB', '3942', 165683.00, 165683.00],
                ],
            ],
            'MAGNUS INTERNATIONAL (PVT) LTD' => [
                'main_open' => 0.00,
                'main_now'  => 0.00,
                'accounts'  => [
                    ['Sampath', '9663', 538607.40, 537527.40],
                    ['Sampath', '9566', 438194.79, 220944.79],
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

                foreach ($accounts as [$bankName, $lastFour, $openBal, $nowBal]) {
                    CardAccount::updateOrCreate(
                        [
                            'showroom_id' => $showroom->id,
                            'bank_name'   => $bankName,
                            'last_four'   => $lastFour,
                        ],
                        [
                            'current_balance'      => $nowBal,
                            'opening_balance'      => $nowBal,
                            'opening_balance_date' => self::OPENING_DATE,
                            'is_active'            => true,
                        ],
                    );

                    if ($openingUserId === null) {
                        continue;
                    }

                    $cardId = CardAccount::where('showroom_id', $showroom->id)
                        ->where('bank_name', $bankName)
                        ->where('last_four', $lastFour)
                        ->value('id');
                    $label = trim($bankName . ' •••• ' . $lastFour);

                    // Snapshot 1 — opening balance on OPENING_DATE.
                    $this->recordBalanceUpdate(
                        $showroom->id, 'bank', $cardId, $label,
                        0, $openBal, 'Opening balance', self::OPENING_DATE, $openingUserId,
                    );
                    // Snapshot 2 — updated balance on UPDATE_DATE.
                    $this->recordBalanceUpdate(
                        $showroom->id, 'bank', $cardId, $label,
                        $openBal, $nowBal, 'Balance update', self::UPDATE_DATE, $openingUserId,
                    );
                }

                // 3. Seed Main Cash as computed daily_cash_entries + ledger rows.
                if ($openingUserId !== null) {
                    $mainOpen  = $config['main_open'];
                    $mainNow   = $config['main_now'];
                    $mainDelta = round($mainNow - $mainOpen, 2);

                    // Remove any stale seeded main-cash entries on other dates.
                    DailyCashEntry::where('showroom_id', $showroom->id)
                        ->where('cash_account_type', 'main')
                        ->whereIn('notes', ['Opening balance', 'Balance update'])
                        ->whereNotIn('entry_date', [self::OPENING_DATE, self::UPDATE_DATE])
                        ->delete();

                    // Opening main-cash entry on OPENING_DATE.
                    if ($mainOpen != 0) {
                        DailyCashEntry::updateOrCreate(
                            [
                                'showroom_id'       => $showroom->id,
                                'entry_date'        => self::OPENING_DATE,
                                'cash_account_type' => 'main',
                                'notes'             => 'Opening balance',
                            ],
                            ['user_id' => $openingUserId, 'cash_amount' => $mainOpen, 'is_locked' => true],
                        );
                    }

                    // Delta entry on UPDATE_DATE so the computed total reaches main_now.
                    if ($mainDelta != 0) {
                        DailyCashEntry::updateOrCreate(
                            [
                                'showroom_id'       => $showroom->id,
                                'entry_date'        => self::UPDATE_DATE,
                                'cash_account_type' => 'main',
                                'notes'             => 'Balance update',
                            ],
                            ['user_id' => $openingUserId, 'cash_amount' => $mainDelta, 'is_locked' => true],
                        );
                    }

                    // Main-cash balance-update ledger rows (both snapshots).
                    if ($mainOpen != 0) {
                        $this->recordBalanceUpdate(
                            $showroom->id, 'main_cash', null, 'Main Cash',
                            0, $mainOpen, 'Opening balance', self::OPENING_DATE, $openingUserId,
                        );
                    }
                    if ($mainNow != 0 || $mainOpen != 0) {
                        $this->recordBalanceUpdate(
                            $showroom->id, 'main_cash', null, 'Main Cash',
                            $mainOpen, $mainNow, 'Balance update', self::UPDATE_DATE, $openingUserId,
                        );
                    }
                }
            }
        });
    }

    /**
     * Idempotently upsert a balance_updates ledger row, keyed by
     * showroom + account_type + account_label + reason.
     */
    private function recordBalanceUpdate(
        int $showroomId,
        string $accountType,
        ?int $cardAccountId,
        string $label,
        float $previous,
        float $new,
        string $reason,
        string $date,
        int $userId,
    ): void {
        $match = [
            'showroom_id'   => $showroomId,
            'account_type'  => $accountType,
            'account_label' => $label,
            'reason'        => $reason,
        ];

        $row = array_merge($match, [
            'card_account_id' => $cardAccountId,
            'previous_amount' => $previous,
            'new_amount'      => $new,
            'change_amount'   => round($new - $previous, 2),
            'user_id'         => $userId,
            'created_at'      => $date . ' 00:00:00',
            'updated_at'      => $date . ' 00:00:00',
        ]);

        $existing = DB::table('balance_updates')->where($match)->first();
        if ($existing) {
            DB::table('balance_updates')->where('id', $existing->id)->update($row);
        } else {
            DB::table('balance_updates')->insert($row);
        }
    }
}
