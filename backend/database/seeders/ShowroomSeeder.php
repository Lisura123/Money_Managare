<?php

namespace Database\Seeders;

use App\Models\Showroom;
use Illuminate\Database\Seeder;

class ShowroomSeeder extends Seeder
{
    public function run(): void
    {
        $showrooms = [
            'CAMERALK (PVT) LTD',
            'SONY ASIA PASIFIC (PVT) LTD',
            'KOSMISCH GLOBAL (PVT) LTD',
            'CLK KANDY (PVT) LTD',
            'CAMERA DOT LK (PVT) LTD',
            'CLK PHOTOGRAPHY (PVT) LTD',
            'NM CREATION',
            'MAGNUS INTERNATIONAL (PVT) LTD',
        ];

        foreach ($showrooms as $name) {
            Showroom::firstOrCreate(
                ['name' => $name],
                ['location' => '', 'is_active' => true],
            );
        }
    }
}
