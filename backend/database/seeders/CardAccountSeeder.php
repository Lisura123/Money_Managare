<?php

namespace Database\Seeders;

use App\Models\CardAccount;
use App\Models\Showroom;
use Illuminate\Database\Seeder;

class CardAccountSeeder extends Seeder
{
    public function run(): void
    {
        // Bank accounts grouped by showroom name. last_four is the trailing
        // identifier shown in the UI; balances start at 0.
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

        foreach ($accountsByShowroom as $showroomName => $accounts) {
            $showroom = Showroom::where('name', $showroomName)->first();
            if (! $showroom) {
                continue;
            }

            foreach ($accounts as [$bankName, $lastFour]) {
                CardAccount::firstOrCreate(
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
            }
        }
    }
}
