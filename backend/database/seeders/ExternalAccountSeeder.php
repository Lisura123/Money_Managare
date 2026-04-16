<?php

namespace Database\Seeders;

use App\Models\ExternalAccount;
use Illuminate\Database\Seeder;

class ExternalAccountSeeder extends Seeder
{
    public function run(): void
    {
        ExternalAccount::updateOrCreate(
            ['name' => "Mano's account"],
            ['balance' => 0.00, 'cash_account_type' => 'mano']
        );
    }
}
