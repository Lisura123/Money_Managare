<?php

namespace Database\Seeders;

use App\Models\Showroom;
use Illuminate\Database\Seeder;

class ShowroomSeeder extends Seeder
{
    public function run(): void
    {
        $showrooms = [
            ['name' => 'Downtown Showroom',  'location' => '123 Main Street, Downtown',    'is_active' => true],
            ['name' => 'Northside Showroom', 'location' => '456 North Avenue, Northside',  'is_active' => true],
            ['name' => 'Eastside Showroom',  'location' => '789 East Blvd, East District', 'is_active' => true],
        ];

        foreach ($showrooms as $data) {
            Showroom::create($data);
        }
    }
}
