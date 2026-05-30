<?php

namespace App\Providers;

use App\Models\CardAccount;
use App\Models\DailyCashEntry;
use App\Models\DailyCardEntry;
use App\Observers\CardAccountObserver;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        JsonResource::withoutWrapping();

        CardAccount::observe(CardAccountObserver::class);

        Relation::morphMap([
            'daily_cash_entries' => DailyCashEntry::class,
            'daily_card_entries' => DailyCardEntry::class,
        ]);
    }
}
