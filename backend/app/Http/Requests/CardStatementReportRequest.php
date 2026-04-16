<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CardStatementReportRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'card_account_id' => ['required', 'integer', 'exists:card_accounts,id'],
            'from'            => ['required', 'date'],
            'to'              => ['required', 'date', 'after_or_equal:from'],
        ];
    }
}
