<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class DailySummaryReportRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'from'        => ['required', 'date'],
            'to'          => ['required', 'date', 'after_or_equal:from'],
            'showroom_id' => ['nullable', 'integer', 'exists:showrooms,id'],
        ];
    }
}
