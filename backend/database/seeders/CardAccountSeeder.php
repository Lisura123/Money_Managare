<?php

namespace Database\Seeders;

use App\Models\CardAccount;
use App\Models\Showroom;
use Illuminate\Database\Seeder;

class CardAccountSeeder extends Seeder
{
    public function run(): void
    {
        $accounts = [
            // Downtown Showroom
            ['bank_name' => 'First National Bank', 'last_four' => '1234', 'current_balance' => 15000.00],
            ['bank_name' => 'City Bank',            'last_four' => '5678', 'current_balance' => 8500.00],
            // Northside Showroom
            ['bank_name' => 'State Bank',           'last_four' => '2345', 'current_balance' => 22000.00],
            ['bank_name' => 'Metro Credit Union',   'last_four' => '6789', 'current_balance' => 5000.00],
            // Eastside Showroom
            ['bank_name' => 'Commerce Bank',        'last_four' => '3456', 'current_balance' => 11000.00],
            ['bank_name' => 'Traders Bank',         'last_four' => '7890', 'current_balance' => 7500.00],
        ];

        $showrooms = Showroom::orderBy('id')->get();

        $perShowroom = array_chunk($accounts, 2);

        foreach ($showrooms as $i => $showroom) {
            foreach ($perShowroom[$i] as $data) {
                CardAccount::create(array_merge($data, [
                    'showroom_id' => $showroom->id,
                    'is_active'   => true,
                ]));
            }
        }
    }
}
