<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CashTransactionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $toExternal = $this->to_external_account_id !== null;
        $toOthers   = ! $toExternal && $this->to_account_type === null;
        $requireNotes = $toOthers || $toExternal;

        return [
            'from_account_type'      => ['required', 'string', 'in:main,mano'],
            'to_account_type'        => $toExternal || $toOthers
                ? ['nullable', 'string', 'in:main,mano']
                : ['required', 'string', 'in:main,mano', 'different:from_account_type'],
            'to_external_account_id' => $toExternal
                ? ['required', 'integer', 'exists:external_accounts,id']
                : ['nullable'],
            'amount'                 => ['required', 'numeric', 'min:0.01'],
            'notes'                  => [$requireNotes ? 'required' : 'nullable', 'string', 'max:1000'],
            'transaction_date'       => ['required', 'date', 'before_or_equal:today'],
        ];
    }
}
