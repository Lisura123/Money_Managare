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
        $showroomId = $this->user()?->showroom_id;

        return [
            'card_account_id' => [
                $isUpdate ? 'sometimes' : 'required',
                'integer',
                Rule::exists('card_accounts', 'id')
                    ->where('showroom_id', $showroomId)
                    ->where('is_active', true),
            ],
            'entry_date' => [$isUpdate ? 'sometimes' : 'required', 'date'],
            'amount'     => [$isUpdate ? 'sometimes' : 'required', 'numeric', 'min:0.01', 'max:99999999.99'],
            'notes'      => ['nullable', 'string', 'max:1000'],
        ];
    }
}
