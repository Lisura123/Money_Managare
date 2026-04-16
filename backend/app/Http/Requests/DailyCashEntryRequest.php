<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class DailyCashEntryRequest extends FormRequest
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
        $isUpdate = $this->isMethod('PUT') || $this->isMethod('PATCH');
        return [
            'entry_date'        => [$isUpdate ? 'sometimes' : 'required', 'date'],
            'cash_amount'       => [$isUpdate ? 'sometimes' : 'required', 'numeric', 'min:0.01', 'max:99999999.99'],
            'notes'             => ['nullable', 'string', 'max:1000'],
            'cash_account_type' => [$isUpdate ? 'sometimes' : 'required', 'string', 'in:main,mano'],
        ];
    }
}
