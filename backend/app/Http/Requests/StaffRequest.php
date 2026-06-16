<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StaffRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $userId   = $this->route('staff') ? $this->route('staff')->id : null;
        $isUpdate = $userId !== null;

        return [
            'name'           => [$isUpdate ? 'sometimes' : 'required', 'string', 'max:255'],
            'email'          => [$isUpdate ? 'sometimes' : 'required', 'email', 'unique:users,email,' . $userId],
            'password'       => [$isUpdate ? 'sometimes' : 'required', 'string', 'min:8'],
            'showroom_id'    => ['sometimes', 'nullable', 'integer', 'exists:showrooms,id'],
            'showroom_ids'   => ['sometimes', 'nullable', 'array'],
            'showroom_ids.*' => ['integer', 'exists:showrooms,id'],
            'is_active'      => ['sometimes', 'boolean'],
        ];
    }
}
