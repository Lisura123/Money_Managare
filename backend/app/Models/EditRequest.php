<?php

namespace App\Models;

use App\Observers\EditRequestObserver;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

#[ObservedBy([EditRequestObserver::class])]
class EditRequest extends Model
{
    protected $fillable = [
        'requestable_type',
        'requestable_id',
        'user_id',
        'showroom_id',
        'status',
        'requested_changes',
        'original_values',
        'reason',
        'admin_remarks',
        'reviewed_by',
        'reviewed_at',
    ];

    protected $casts = [
        'requested_changes' => 'array',
        'original_values'   => 'array',
        'reviewed_at'       => 'datetime',
    ];

    public function requestable()
    {
        return $this->morphTo();
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function showroom()
    {
        return $this->belongsTo(Showroom::class);
    }

    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', 'pending');
    }

    public function scopeApproved(Builder $query): Builder
    {
        return $query->where('status', 'approved');
    }

    public function scopeRejected(Builder $query): Builder
    {
        return $query->where('status', 'rejected');
    }

    public function scopeForShowroom(Builder $query, int $showroomId): Builder
    {
        return $query->where('showroom_id', $showroomId);
    }
}
