<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CardAccountRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'bank_name'       => ['required', 'string', 'max:255'],
            'last_four'       => ['required', 'string', 'size:4', 'regex:/^\d{4}$/'],
            'current_balance' => ['sometimes', 'numeric', 'min:0'],
            'is_active'       => ['sometimes', 'boolean'],
        ];
    }
}
