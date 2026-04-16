<?php

namespace Database\Seeders;

use App\Models\Showroom;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin
        User::create([
            'name'        => 'Admin User',
            'email'       => 'admin@admin.com',
            'password'    => Hash::make('password'),
            'role'        => 'admin',
            'showroom_id' => null,
            'is_active'   => true,
        ]);

        $showrooms = Showroom::orderBy('id')->get();

        $staffData = [
            ['name' => 'Staff Downtown',  'email' => 'staff.downtown@example.com'],
            ['name' => 'Staff Northside', 'email' => 'staff.northside@example.com'],
            ['name' => 'Staff Eastside',  'email' => 'staff.eastside@example.com'],
        ];

        foreach ($staffData as $index => $data) {
            User::create([
                'name'        => $data['name'],
                'email'       => $data['email'],
                'password'    => Hash::make('password'),
                'role'        => 'staff',
                'showroom_id' => $showrooms[$index]->id,
                'is_active'   => true,
            ]);
        }
    }
}
