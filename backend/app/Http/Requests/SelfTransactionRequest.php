<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SelfTransactionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $hasFromCard     = $this->from_card_account_id !== null;
        $hasFromExternal = $this->from_external_account_id !== null;

        $toExternal = $this->to_external_account_id !== null;
        $toCard     = $this->to_card_account_id !== null;
        $toMain     = $this->to_account_type === 'main';
        $toOthers   = ! $toExternal && ! $toCard && ! $toMain;

        return [
            'from_card_account_id'     => $hasFromCard
                ? ['required', 'integer', 'exists:card_accounts,id']
                : ['nullable'],
            'from_external_account_id' => $hasFromExternal
                ? ['required', 'integer', 'exists:external_accounts,id']
                : ['nullable'],
            'from_account_type'        => ['nullable', 'string', 'in:main'],
            'to_card_account_id'       => ($toExternal || $toOthers || $toMain)
                ? ['nullable']
                : ($toCard ? ['required', 'integer', 'exists:card_accounts,id'] : ['nullable']),
            'to_external_account_id'   => $toExternal
                ? ['required', 'integer', 'exists:external_accounts,id']
                : ['nullable'],
            'to_account_type'          => ['nullable', 'string', 'in:main'],
            'from_showroom_id'         => ['nullable', 'integer', 'exists:showrooms,id'],
            'to_showroom_id'           => ['nullable', 'integer', 'exists:showrooms,id'],
            'amount'                   => ['required', 'numeric', 'min:0.01'],
            'notes'                    => [$toOthers ? 'required' : 'nullable', 'string', 'max:1000'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            if (
                ! $this->from_card_account_id &&
                ! $this->from_external_account_id &&
                $this->from_account_type !== 'main'
            ) {
                $v->errors()->add('from', 'A source account must be specified.');
            }
        });
    }
}
