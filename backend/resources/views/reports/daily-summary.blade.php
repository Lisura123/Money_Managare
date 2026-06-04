@extends('reports.layout')

@section('content')

{{-- ══════════════════════════════════════════════
     HEADER
══════════════════════════════════════════════ --}}
<div class="report-header">
  <div class="brand">Money Manager &mdash; Admin Report</div>
  <h1>Daily Summary Report</h1>
  <div class="meta">
    @if ($isSingleDay)
      <span>Date: <strong>{{ \Carbon\Carbon::parse($from)->format('d M Y') }}</strong></span>
    @else
      <span>Period: <strong>{{ \Carbon\Carbon::parse($from)->format('d M Y') }}</strong>
        &ndash; <strong>{{ \Carbon\Carbon::parse($to)->format('d M Y') }}</strong></span>
    @endif
    <span>Showrooms: <strong>{{ $showrooms->count() }}</strong></span>
  </div>
</div>

{{-- ══════════════════════════════════════════════
     GRAND TOTALS — COLOUR SUMMARY CARDS
══════════════════════════════════════════════ --}}
<table style="width:100%; border-collapse:separate; border-spacing:6px; margin-bottom:20px;">
  <tr>
    <td style="background:#ecfdf5; border:2px solid #6ee7b7; border-radius:6px; padding:10px 14px; text-align:center; width:20%;">
      <div style="font-size:9px; color:#065f46; text-transform:uppercase; letter-spacing:0.8px; font-weight:700; margin-bottom:5px;">Main Cash</div>
      <div style="font-size:18px; font-weight:700; color:#065f46; font-family:'Courier New',monospace;">{{ number_format($grandMainCashTotal, 2) }}</div>
    </td>
    <td style="background:#f5f3ff; border:2px solid #c4b5fd; border-radius:6px; padding:10px 14px; text-align:center; width:20%;">
      <div style="font-size:9px; color:#5b21b6; text-transform:uppercase; letter-spacing:0.8px; font-weight:700; margin-bottom:5px;">Mano's Cash</div>
      <div style="font-size:18px; font-weight:700; color:#5b21b6; font-family:'Courier New',monospace;">{{ number_format($grandManoCashTotal, 2) }}</div>
    </td>
    <td style="background:#eff6ff; border:2px solid #93c5fd; border-radius:6px; padding:10px 14px; text-align:center; width:20%;">
      <div style="font-size:9px; color:#1e40af; text-transform:uppercase; letter-spacing:0.8px; font-weight:700; margin-bottom:5px;">Total Cash</div>
      <div style="font-size:18px; font-weight:700; color:#1e40af; font-family:'Courier New',monospace;">{{ number_format($grandCashTotal, 2) }}</div>
    </td>
    <td style="background:#fefce8; border:2px solid #fde68a; border-radius:6px; padding:10px 14px; text-align:center; width:20%;">
      <div style="font-size:9px; color:#92400e; text-transform:uppercase; letter-spacing:0.8px; font-weight:700; margin-bottom:5px;">Total Card</div>
      <div style="font-size:18px; font-weight:700; color:#92400e; font-family:'Courier New',monospace;">{{ number_format($grandCardTotal, 2) }}</div>
    </td>
    <td style="background:#1e3a5f; border:2px solid #1e3a5f; border-radius:6px; padding:10px 14px; text-align:center; width:20%;">
      <div style="font-size:9px; color:#93c5fd; text-transform:uppercase; letter-spacing:0.8px; font-weight:700; margin-bottom:5px;">Grand Total</div>
      <div style="font-size:18px; font-weight:700; color:#ffffff; font-family:'Courier New',monospace;">{{ number_format($grandCashTotal + $grandCardTotal, 2) }}</div>
    </td>
  </tr>
</table>

{{-- ══════════════════════════════════════════════
     PER-SHOWROOM SECTIONS
══════════════════════════════════════════════ --}}
@forelse ($showrooms as $showroom)

  {{-- Showroom header bar --}}
  <div style="background:#1e3a5f; color:#fff; padding:9px 14px; border-radius:5px 5px 0 0; margin-top:4px;">
    <span style="font-size:14px; font-weight:700;">{{ $showroom->name }}</span>
    <span style="font-size:11px; opacity:0.7; margin-left:10px;">&mdash; {{ $showroom->location }}</span>
  </div>
  <div style="border:1px solid #e2e8f0; border-top:none; border-radius:0 0 5px 5px; padding:12px; margin-bottom:4px;">

    {{-- Cash Entries --}}
    <div style="background:#f0fdf4; border-left:4px solid #34d399; padding:5px 10px; margin-bottom:8px; font-size:10px; font-weight:700; color:#065f46;">
      &#9654;&nbsp; Cash Entries
    </div>

    @if ($showroom->dailyCashEntries->isEmpty())
      <p style="color:#9ca3af; font-style:italic; font-size:10px; padding:4px 8px; margin-bottom:8px;">No cash entries for this period.</p>
    @else
      @foreach ($showroom->cash_entries_by_type as $accountType => $typeEntries)
        @php
          $isMain  = $accountType !== 'mano';
          $acColor = $isMain ? '#065f46' : '#5b21b6';
          $acBg    = $isMain ? '#ecfdf5' : '#f5f3ff';
          $acBdr   = $isMain ? '#6ee7b7' : '#c4b5fd';
          $acLabel = $isMain ? 'Main Account' : "Mano's Account";
        @endphp
        <div style="font-size:10px; font-weight:700; color:{{ $acColor }}; background:{{ $acBg }}; border:1px solid {{ $acBdr }}; padding:3px 10px; margin:4px 0 3px; border-radius:3px; display:inline-block;">
          {{ $acLabel }}
        </div>
        <table>
          <thead>
            <tr>
              @unless ($isSingleDay)<th>Date</th>@endunless
              <th>Submitted By</th>
              <th>Notes</th>
              <th class="right">Amount</th>
              <th class="center">Locked</th>
            </tr>
          </thead>
          <tbody>
            @foreach ($typeEntries as $entry)
            <tr>
              @unless ($isSingleDay)<td>{{ \Carbon\Carbon::parse($entry->entry_date)->format('d M Y') }}</td>@endunless
              <td>{{ $entry->user->name ?? '—' }}</td>
              <td class="text-muted">{{ $entry->notes ?: '—' }}</td>
              <td class="amount right" style="color:{{ $acColor }}; font-weight:600;">{{ number_format($entry->cash_amount, 2) }}</td>
              <td class="center" style="color:{{ $entry->is_locked ? '#dc2626' : '#9ca3af' }}; font-weight:{{ $entry->is_locked ? '700' : '400' }};">
                {{ $entry->is_locked ? 'Yes' : '—' }}
              </td>
            </tr>
            @endforeach
            <tr class="subtotals-row">
              <td colspan="{{ $isSingleDay ? 2 : 3 }}">{{ $acLabel }} Subtotal</td>
              <td class="amount right">{{ number_format($typeEntries->sum('cash_amount'), 2) }}</td>
              <td></td>
            </tr>
          </tbody>
        </table>
      @endforeach
    @endif

    {{-- Card Entries --}}
    <div style="background:#eff6ff; border-left:4px solid #60a5fa; padding:5px 10px; margin:12px 0 8px; font-size:10px; font-weight:700; color:#1e40af;">
      &#9654;&nbsp; Card Entries
    </div>

    @if ($showroom->dailyCardEntries->isEmpty())
      <p style="color:#9ca3af; font-style:italic; font-size:10px; padding:4px 8px; margin-bottom:8px;">No card entries for this period.</p>
    @else
      @foreach ($showroom->card_entries_by_account as $group)
        @php $acct = $group['card_account']; @endphp
        <div style="font-size:10px; font-weight:700; color:#1e40af; background:#dbeafe; border:1px solid #93c5fd; padding:3px 10px; margin:4px 0 3px; border-radius:3px; display:inline-block;">
          {{ $acct ? $acct->bank_name . '  ••••' . $acct->last_four : 'Unknown Card' }}
        </div>
        <table>
          <thead>
            <tr>
              @unless ($isSingleDay)<th>Date</th>@endunless
              <th>Submitted By</th>
              <th>Notes</th>
              <th class="right">Amount</th>
            </tr>
          </thead>
          <tbody>
            @foreach ($group['entries'] as $entry)
            <tr>
              @unless ($isSingleDay)<td>{{ \Carbon\Carbon::parse($entry->entry_date)->format('d M Y') }}</td>@endunless
              <td>{{ $entry->user->name ?? '—' }}</td>
              <td class="text-muted">{{ $entry->notes ?: '—' }}</td>
              <td class="amount right" style="color:#1e40af; font-weight:600;">{{ number_format($entry->amount, 2) }}</td>
            </tr>
            @endforeach
            <tr class="subtotals-row">
              <td colspan="{{ $isSingleDay ? 2 : 3 }}">Account Subtotal</td>
              <td class="amount right">{{ number_format($group['total'], 2) }}</td>
            </tr>
          </tbody>
        </table>
      @endforeach
    @endif

    {{-- Showroom totals row --}}
    <table style="width:auto; margin:14px 0 0 auto;">
      <tr>
        <th style="background:#ecfdf5; color:#065f46; border-color:#6ee7b7; min-width:76px;">Main Cash</th>
        <th style="background:#f5f3ff; color:#5b21b6; border-color:#c4b5fd; min-width:76px;">Mano's Cash</th>
        <th style="background:#eff6ff; color:#1e40af; border-color:#93c5fd; min-width:76px;">Total Cash</th>
        <th style="background:#fefce8; color:#92400e; border-color:#fde68a; min-width:76px;">Total Card</th>
        <th style="background:#1e3a5f; color:#fff;    border-color:#1e3a5f; min-width:76px;">Grand Total</th>
      </tr>
      <tr>
        <td class="amount right" style="background:#ecfdf5; color:#065f46; font-weight:700; border-color:#6ee7b7;">{{ number_format($showroom->main_cash_total, 2) }}</td>
        <td class="amount right" style="background:#f5f3ff; color:#5b21b6; font-weight:700; border-color:#c4b5fd;">{{ number_format($showroom->mano_cash_total, 2) }}</td>
        <td class="amount right" style="background:#eff6ff; color:#1e40af; font-weight:700; border-color:#93c5fd;">{{ number_format($showroom->cash_total, 2) }}</td>
        <td class="amount right" style="background:#fefce8; color:#92400e; font-weight:700; border-color:#fde68a;">{{ number_format($showroom->card_total, 2) }}</td>
        <td class="amount right" style="background:#1e3a5f; color:#fff; font-weight:700; border-color:#1e3a5f; font-size:12px;">{{ number_format($showroom->cash_total + $showroom->card_total, 2) }}</td>
      </tr>
    </table>

  </div>{{-- end showroom card --}}

  @if (!$loop->last)
    <div style="margin:18px 0; border-top:2px dashed #cbd5e1;"></div>
  @endif

@empty
  <div style="color:#9ca3af; font-style:italic; padding:24px; text-align:center; border:1px dashed #e2e8f0; border-radius:6px; margin-top:12px;">
    No showrooms found for the selected period.
  </div>
@endforelse

@endsection
