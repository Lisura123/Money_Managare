<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReviewEditRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        // admin_remarks is required only for rejection
        $isReject = str_contains($this->route()->getName() ?? '', 'reject')
            || str_ends_with($this->path(), '/reject');

        return [
            'admin_remarks' => $isReject
                ? ['required', 'string', 'min:5']
                : ['nullable', 'string', 'max:1000'],
        ];
    }
}
