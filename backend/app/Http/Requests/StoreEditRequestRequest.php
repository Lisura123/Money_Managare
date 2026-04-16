<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreEditRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'entry_type'              => ['required', 'in:cash,card'],
            'entry_id'                => ['required', 'integer', 'min:1'],
            'requested_changes'       => ['required', 'array', 'min:1'],
            'requested_changes.cash_amount' => ['sometimes', 'numeric', 'min:0.01'],
            'requested_changes.amount'      => ['sometimes', 'numeric', 'min:0.01'],
            'requested_changes.notes'       => ['sometimes', 'nullable', 'string', 'max:1000'],
            'reason'                  => ['required', 'string', 'min:10'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason.min' => 'Please provide at least 10 characters explaining why this edit is needed.',
        ];
    }
}
