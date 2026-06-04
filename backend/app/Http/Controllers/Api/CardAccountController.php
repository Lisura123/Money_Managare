<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CardAccountRequest;
use App\Http\Resources\CardAccountResource;
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
        $cardAccount->update($request->validated());
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
     * Staff: list card accounts for their own showroom
     */
    public function myShowroomAccounts(): JsonResponse
    {
        $user = auth()->user();
        $accounts = CardAccount::where('showroom_id', $user->showroom_id)
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
        $cardAccount->update($validated);
        return response()->json(new CardAccountResource($cardAccount->load('showroom')));
    }

    // Flat DELETE /card-accounts/{id} — iOS app deletes by ID
    public function destroyFlat(CardAccount $cardAccount): JsonResponse
    {
        $cardAccount->delete();
        return response()->json(['message' => 'Card account deleted.']);
    }
}
