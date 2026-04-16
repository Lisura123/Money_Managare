<?php

namespace App\Providers;

use App\Models\CardAccount;
use App\Models\DailyCashEntry;
use App\Models\DailyCardEntry;
use App\Observers\CardAccountObserver;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        CardAccount::observe(CardAccountObserver::class);

        Relation::morphMap([
            'daily_cash_entries' => DailyCashEntry::class,
            'daily_card_entries' => DailyCardEntry::class,
        ]);
    }
}
