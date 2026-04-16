<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ShowroomReportRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'showroom_id' => ['required', 'integer', 'exists:showrooms,id'],
            'from'        => ['required', 'date'],
            'to'          => ['required', 'date', 'after_or_equal:from'],
        ];
    }
}
