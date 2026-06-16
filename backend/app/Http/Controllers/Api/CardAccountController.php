<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CardAccountRequest;
use App\Http\Resources\CardAccountResource;
use App\Models\BalanceUpdate;
use App\Models\CardAccount;
use App\Models\Showroom;
use App\Observers\CardAccountObserver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CardAccountController extends Controller
{
    public function index(Showroom $showroom): JsonResponse
    {
        $accounts = $showroom->cardAccounts()->get();
        return CardAccountResource::collection($accounts)->toResponse(request());
    }

    public function store(CardAccountRequest $request, Showroom $showroom): JsonResponse
    {
        $account = $showroom->cardAccounts()->create($request->validated());
        return response()->json(new CardAccountResource($account), 201);
    }

    public function show(Showroom $showroom, CardAccount $cardAccount): JsonResponse
    {
        abort_if($cardAccount->showroom_id !== $showroom->id, 404);
        return response()->json(new CardAccountResource($cardAccount->load('showroom')));
    }

    public function update(CardAccountRequest $request, Showroom $showroom, CardAccount $cardAccount): JsonResponse
    {
        abort_if($cardAccount->showroom_id !== $showroom->id, 404);
        $previousBalance = (float) $cardAccount->current_balance;
        $cardAccount->update($request->validated());
        $this->logBalanceChange($request, $cardAccount, $previousBalance);
        return response()->json(new CardAccountResource($cardAccount->load('showroom')));
    }

    public function destroy(Showroom $showroom, CardAccount $cardAccount): JsonResponse
    {
        abort_if($cardAccount->showroom_id !== $showroom->id, 404);
        $cardAccount->delete();
        return response()->json(['message' => 'Card account deleted.']);
    }

    /**
     * Admin: list all card accounts (flat, for cross-showroom pickers)
     */
    public function adminIndex(): JsonResponse
    {
        $accounts = CardAccount::with('showroom')->get();
        return CardAccountResource::collection($accounts)->toResponse(request());
    }

    /**
     * Staff: list card accounts for their assigned showroom(s).
     *
     * Staff assigned to multiple showrooms get accounts across all of them, or
     * — when a `showroom_id` query param is supplied and assigned to them — the
     * accounts for that single showroom.
     */
    public function myShowroomAccounts(Request $request): JsonResponse
    {
        $user = auth()->user();

        // All showrooms this staff member is assigned to (primary + pivot).
        $assignedIds = $user->showrooms()->pluck('showrooms.id')
            ->push($user->showroom_id)
            ->unique()
            ->filter()
            ->values();

        $showroomIds = $assignedIds;
        if ($request->filled('showroom_id')) {
            $requested = (int) $request->showroom_id;
            if (! $assignedIds->contains($requested)) {
                return response()->json(['message' => 'You are not assigned to this showroom.'], 403);
            }
            $showroomIds = collect([$requested]);
        }

        $accounts = CardAccount::whereIn('showroom_id', $showroomIds)
            ->where('is_active', true)
            ->get();
        return CardAccountResource::collection($accounts)->toResponse(request());
    }

    // Flat POST /card-accounts — iOS app sends showroom_id in body
    public function storeFlat(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'showroom_id'     => ['required', 'integer', 'exists:showrooms,id'],
            'bank_name'       => ['required', 'string', 'max:255'],
            'last_four'       => ['required', 'string', 'size:4', 'regex:/^\d{4}$/'],
            'current_balance' => ['sometimes', 'numeric', 'min:0'],
            'is_active'       => ['sometimes', 'boolean'],
        ]);
        $showroom = Showroom::findOrFail($validated['showroom_id']);
        $account  = $showroom->cardAccounts()->create($validated);
        return response()->json(new CardAccountResource($account->load('showroom')), 201);
    }

    // Flat PUT/PATCH /card-accounts/{id} — iOS app updates by ID
    public function updateFlat(Request $request, CardAccount $cardAccount): JsonResponse
    {
        $validated = $request->validate([
            'showroom_id'     => ['sometimes', 'integer', 'exists:showrooms,id'],
            'bank_name'       => ['sometimes', 'string', 'max:255'],
            'last_four'       => ['sometimes', 'string', 'size:4', 'regex:/^\d{4}$/'],
            'current_balance' => ['sometimes', 'numeric', 'min:0'],
            'is_active'       => ['sometimes', 'boolean'],
        ]);
        $previousBalance = (float) $cardAccount->current_balance;
        $cardAccount->update($validated);
        $this->logBalanceChange($request, $cardAccount, $previousBalance);
        return response()->json(new CardAccountResource($cardAccount->load('showroom')));
    }

    // Flat DELETE /card-accounts/{id} — iOS app deletes by ID
    public function destroyFlat(CardAccount $cardAccount): JsonResponse
    {
        $cardAccount->delete();
        return response()->json(['message' => 'Card account deleted.']);
    }

    /**
     * Record a manual bank balance change in the balance_updates log so it
     * appears in the Records → Balance Updates section.
     */
    private function logBalanceChange(Request $request, CardAccount $cardAccount, float $previousBalance): void
    {
        $newBalance = (float) $cardAccount->fresh()->current_balance;
        if (abs($newBalance - $previousBalance) < 0.001) {
            return;
        }

        BalanceUpdate::create([
            'showroom_id'     => $cardAccount->showroom_id,
            'account_type'    => 'bank',
            'card_account_id' => $cardAccount->id,
            'account_label'   => trim(($cardAccount->bank_name ?? 'Bank') . ' •••• ' . ($cardAccount->last_four ?? '')),
            'previous_amount' => $previousBalance,
            'new_amount'      => $newBalance,
            'change_amount'   => $newBalance - $previousBalance,
            'reason'          => $request->input('reason'),
            'user_id'         => $request->user()->id,
        ]);
    }
}
