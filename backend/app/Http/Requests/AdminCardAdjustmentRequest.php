<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AdminCardAdjustmentRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    protected function prepareForValidation(): void
    {
        // Accept 'adjustment_amount' as alias for 'adjusted_amount'
        if ($this->has('adjustment_amount') && ! $this->has('adjusted_amount')) {
            $this->merge(['adjusted_amount' => $this->adjustment_amount]);
        }
    }

    public function rules(): array
    {
        return [
            'adjusted_amount' => ['required', 'numeric'],
            'reason'          => ['required', 'string', 'max:1000'],
            'card_account_id' => ['sometimes', 'integer', 'exists:card_accounts,id'],
        ];
    }
}
