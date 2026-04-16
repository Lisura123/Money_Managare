<?php

namespace Database\Seeders;

use App\Models\DailyCashEntry;
use App\Models\DailyCardEntry;
use App\Models\EditRequest;
use App\Models\User;
use Illuminate\Database\Seeder;

class EditRequestSeeder extends Seeder
{
    public function run(): void
    {
        $staff = User::where('role', 'staff')->first();
        $admin = User::where('role', 'admin')->first();

        if (! $staff || ! $admin) {
            return;
        }

        // Pick two recent unlocked cash entries belonging to the staff
        $cashEntries = DailyCashEntry::where('user_id', $staff->id)
            ->where('is_locked', false)
            ->orderByDesc('entry_date')
            ->take(2)
            ->get();

        // Pick one recent unlocked card entry
        $cardEntry = DailyCardEntry::where('user_id', $staff->id)
            ->where('is_locked', false)
            ->orderByDesc('entry_date')
            ->first();

        // 1. Pending cash edit request
        if ($cashEntries->count() >= 1) {
            $ce = $cashEntries->first();
            EditRequest::create([
                'requestable_type'  => 'daily_cash_entries',
                'requestable_id'    => $ce->id,
                'user_id'           => $staff->id,
                'showroom_id'       => $staff->showroom_id,
                'status'            => 'pending',
                'requested_changes' => ['cash_amount' => round((float) $ce->cash_amount + 500, 2)],
                'original_values'   => ['cash_amount' => $ce->cash_amount],
                'reason'            => 'I entered the wrong amount. The actual cash collected was higher.',
            ]);
        }

        // 2. Pending card edit request
        if ($cardEntry) {
            EditRequest::create([
                'requestable_type'  => 'daily_card_entries',
                'requestable_id'    => $cardEntry->id,
                'user_id'           => $staff->id,
                'showroom_id'       => $staff->showroom_id,
                'status'            => 'pending',
                'requested_changes' => ['notes' => 'Corrected note: card terminal was down briefly.'],
                'original_values'   => ['notes' => $cardEntry->notes],
                'reason'            => 'I need to update the notes to reflect the correct situation at the terminal.',
            ]);
        }

        // 3. Approved cash edit request
        if ($cashEntries->count() >= 2) {
            $ce2 = $cashEntries->last();
            EditRequest::create([
                'requestable_type'  => 'daily_cash_entries',
                'requestable_id'    => $ce2->id,
                'user_id'           => $staff->id,
                'showroom_id'       => $staff->showroom_id,
                'status'            => 'approved',
                'requested_changes' => ['cash_amount' => round((float) $ce2->cash_amount - 200, 2), 'notes' => 'Corrected amount after reconciliation.'],
                'original_values'   => ['cash_amount' => $ce2->cash_amount, 'notes' => $ce2->notes],
                'reason'            => 'After end-of-day reconciliation I realised the amount was over-reported by Rs. 200.',
                'admin_remarks'     => 'Verified with the showroom manager. Approved.',
                'reviewed_by'       => $admin->id,
                'reviewed_at'       => now()->subHours(2),
            ]);
        }

        // 4. Rejected cash edit request (use first cash entry if available — second request for same entry won't conflict since first is pending, so use cardEntry if cash isn't available)
        if ($cardEntry) {
            EditRequest::create([
                'requestable_type'  => 'daily_card_entries',
                'requestable_id'    => $cardEntry->id,
                'user_id'           => $staff->id,
                'showroom_id'       => $staff->showroom_id,
                'status'            => 'rejected',
                'requested_changes' => ['amount' => round((float) $cardEntry->amount + 1000, 2)],
                'original_values'   => ['amount' => $cardEntry->amount],
                'reason'            => 'Customer paid more than recorded. Please approve the updated amount.',
                'admin_remarks'     => 'Amount cannot be verified without a receipt. Please resubmit with documentation.',
                'reviewed_by'       => $admin->id,
                'reviewed_at'       => now()->subHour(),
            ]);
        }
    }
}
