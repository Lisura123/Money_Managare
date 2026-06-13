<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DailyCashEntryRequest;
use App\Http\Resources\DailyCashEntryResource;
use App\Models\CashTransaction;
use App\Models\DailyCashEntry;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DailyCashEntryController extends Controller
{
    public function store(DailyCashEntryRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->isAdmin() && ! Setting::cashEntriesEnabled()) {
            return response()->json(['message' => 'Cash entries are currently disabled by the administrator.'], 422);
        }

        if (! $user->isAdmin() && ! Setting::isWithinEditWindow()) {
            return response()->json(['message' => 'Entry submission is only allowed during the edit window.'], 422);
        }

        $entry = DailyCashEntry::create([
            'showroom_id'       => $user->showroom_id,
            'user_id'           => $user->id,
            'entry_date'        => $request->entry_date,
            'cash_amount'       => $request->cash_amount,
            'notes'             => $request->notes,
            'cash_account_type' => $request->cash_account_type ?? 'main',
        ]);

        return response()->json(new DailyCashEntryResource($entry->load('showroom', 'user')), 201);
    }

    public function myHistory(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = DailyCashEntry::where('user_id', $user->id)
            ->with('showroom', 'adjustments')
            ->orderByDesc('entry_date');

        if ($request->filled('cash_account_type')) {
            $query->where('cash_account_type', $request->cash_account_type);
        }

        $entries = $query->paginate(20);

        return response()->json(DailyCashEntryResource::collection($entries)->response()->getData(true));
    }
    public function index(Request $request): JsonResponse
    {
        $query = DailyCashEntry::with('showroom', 'user', 'adjustments')
            // Exclude zero-amount carrier entries created solely to anchor a Main Cash
            // adjustment. The adjustment itself is shown under Records → Cash Adjustments.
            ->where('cash_amount', '>', 0)
            // Exclude seeded opening-balance entries — these are shown under
            // Records → Balance Updates instead.
            ->where('notes', '!=', 'Opening balance');

        if ($request->filled('showroom_id')) {
            $query->where('showroom_id', $request->showroom_id);
        }

        if ($request->filled('cash_account_type')) {
            $query->where('cash_account_type', $request->cash_account_type);
        }

        if ($request->filled('date')) {
            $query->whereDate('entry_date', $request->date);
        }

        if ($request->filled('from') && $request->filled('to')) {
            $query->whereBetween('entry_date', [$request->from, $request->to]);
        }

        // Calculate total across ALL matching entries (not just the current page)
        $totalAmount = (clone $query)->sum('cash_amount');

        $entries  = $query->orderByDesc('entry_date')->paginate(20);
        $response = DailyCashEntryResource::collection($entries)->response()->getData(true);

        // Inject total_amount into the existing meta object
        $response['meta']['total_amount'] = round((float) $totalAmount, 2);

        return response()->json($response);
    }

    /**
     * Admin: update a cash entry (can edit locked entries).
     * Staff must submit an edit request instead.
     */
    public function summary(): JsonResponse
    {
        $types = ['main', 'mano'];
        $result = [];

        foreach ($types as $type) {
            $entries   = (float) DailyCashEntry::where('cash_account_type', $type)->sum('cash_amount');
            $outflows  = (float) CashTransaction::where('from_account_type', $type)
                ->whereNull('to_account_type')  // to external / others — money leaves the system
                ->sum('amount');
            $transfers_out = (float) CashTransaction::where('from_account_type', $type)
                ->whereNotNull('to_account_type')
                ->sum('amount');
            $transfers_in  = (float) CashTransaction::where('to_account_type', $type)
                ->sum('amount');

            $result[$type] = $entries - $outflows - $transfers_out + $transfers_in;
        }

        return response()->json($result);
    }

    public function update(DailyCashEntryRequest $request, DailyCashEntry $dailyCashEntry): JsonResponse
    {
        $user = $request->user();

        if (! $user->isAdmin()) {
            return response()->json(['message' => 'Please submit an edit request instead.'], 403);
        }

        $dailyCashEntry->update($request->validated());

        return response()->json(new DailyCashEntryResource($dailyCashEntry->load('showroom', 'user')));
    }

    public function destroy(DailyCashEntry $dailyCashEntry): JsonResponse
    {
        $dailyCashEntry->adjustments()->delete();
        $dailyCashEntry->delete();

        return response()->json(['message' => 'Cash entry deleted.']);
    }

    public function bulkDestroy(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer']);

        $entries = DailyCashEntry::whereIn('id', $request->ids)->get();

        foreach ($entries as $entry) {
            $entry->adjustments()->delete();
            $entry->delete();
        }

        return response()->json(['message' => "Deleted {$entries->count()} cash entries."]);
    }
}
