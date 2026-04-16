<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SettingRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'value'       => ['required', 'string'],
            'description' => ['nullable', 'string', 'max:500'],
        ];
    }
}
