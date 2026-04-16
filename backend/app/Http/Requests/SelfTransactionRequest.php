<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SelfTransactionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $toExternal = $this->to_external_account_id !== null;
        $toOthers   = ! $toExternal && ($this->to_card_account_id === null || $this->to_card_account_id === 'others');
        $requireNotes = $toOthers || $toExternal;

        return [
            'from_card_account_id'    => ['required', 'integer', 'exists:card_accounts,id'],
            'to_card_account_id'      => $toExternal || $toOthers
                ? ['nullable']
                : ['required', 'integer', 'exists:card_accounts,id', 'different:from_card_account_id'],
            'to_external_account_id'  => $toExternal
                ? ['required', 'integer', 'exists:external_accounts,id']
                : ['nullable'],
            'amount'                  => ['required', 'numeric', 'min:0.01'],
            'notes'                   => [$requireNotes ? 'required' : 'nullable', 'string', 'max:1000'],
        ];
    }
}
