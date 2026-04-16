<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            ShowroomSeeder::class,
            UserSeeder::class,
            CardAccountSeeder::class,
            SettingsSeeder::class,
            DailyEntrySeeder::class,
            EditRequestSeeder::class,
            ExternalAccountSeeder::class,
        ]);
    }
}
