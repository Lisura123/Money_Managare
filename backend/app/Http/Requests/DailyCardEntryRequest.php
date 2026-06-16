<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class DailyCardEntryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    protected function prepareForValidation(): void
    {
        // Accept 'date' as an alias for 'entry_date'
        if ($this->has('date') && ! $this->has('entry_date')) {
            $this->merge(['entry_date' => $this->date]);
        }
    }

    public function rules(): array
    {
        $isUpdate   = $this->isMethod('PUT') || $this->isMethod('PATCH');
        $user       = $this->user();

        // Resolve all showrooms the staff member is assigned to (primary + pivot).
        // Admins may submit for any showroom.
        $allowedShowroomIds = $user && ! $user->isAdmin()
            ? $user->showrooms()->pluck('showrooms.id')->push($user->showroom_id)->unique()->filter()->values()->all()
            : null;

        $cardAccountExists = Rule::exists('card_accounts', 'id')->where('is_active', true);
        if ($allowedShowroomIds !== null) {
            $cardAccountExists->whereIn('showroom_id', $allowedShowroomIds);
        }

        return [
            'card_account_id' => [
                $isUpdate ? 'sometimes' : 'required',
                'integer',
                $cardAccountExists,
            ],
            'showroom_id' => ['sometimes', 'nullable', 'integer', 'exists:showrooms,id'],
            'entry_date' => [$isUpdate ? 'sometimes' : 'required', 'date'],
            'amount'     => [$isUpdate ? 'sometimes' : 'required', 'numeric', 'min:0.01', 'max:99999999.99'],
            'notes'      => ['nullable', 'string', 'max:1000'],
        ];
    }
}
