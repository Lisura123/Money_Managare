@extends('reports.layout')

@section('content')

<div class="report-header">
  <div class="brand">Money Manager &mdash; Admin Report</div>
  <h1>Showroom Report &mdash; {{ $showroom->name }}</h1>
  <div class="meta">
    <span>Location: <strong>{{ $showroom->location }}</strong></span>
    <span>Period: <strong>{{ \Carbon\Carbon::parse($from)->format('d M Y') }}</strong>
      &ndash; <strong>{{ \Carbon\Carbon::parse($to)->format('d M Y') }}</strong></span>
  </div>
</div>

{{-- Summary boxes --}}
<table style="width:auto; margin-bottom:16px;">
  <tr>
    <th>Main Cash</th>
    <th>Mano's Cash</th>
    <th>Cash Adj Total</th>
    <th>Card Total</th>
    <th>Card Adj Total</th>
    <th>Net Total</th>
  </tr>
  <tr class="totals-row">
    @php
      $mainCashTotal = $cashEntries->where('cash_account_type', 'main')->sum('cash_amount');
      $manoCashTotal = $cashEntries->where('cash_account_type', 'mano')->sum('cash_amount');
    @endphp
    <td class="amount right">{{ number_format($mainCashTotal, 2) }}</td>
    <td class="amount right">{{ number_format($manoCashTotal, 2) }}</td>
    <td class="amount right">{{ number_format($cashAdjTotal, 2) }}</td>
    <td class="amount right">{{ number_format($cardTotal, 2) }}</td>
    <td class="amount right">{{ number_format($cardAdjTotal, 2) }}</td>
    <td class="amount right">
      {{ number_format($cashTotal + $cashAdjTotal + $cardTotal + $cardAdjTotal, 2) }}
    </td>
  </tr>
</table>

{{-- ── Cash Entries ─────────────────────────────────────── --}}
<div class="section-title">Daily Cash Entries</div>

@if ($cashEntries->isEmpty())
  <div class="no-data">No cash entries for this period.</div>
@else
  @foreach ($cashEntries->groupBy('cash_account_type')->sortKeys() as $accountType => $typeEntries)
    @php $typeLabel = $accountType === 'mano' ? "Mano's Account" : 'Main Account'; @endphp
    <div style="font-size:11px; font-weight:700; color:{{ $accountType === 'mano' ? '#5b21b6' : '#065f46' }}; margin: 8px 0 4px;">
      {{ $typeLabel }}
    </div>
    <table>
      <thead>
        <tr>
          <th>Date</th>
          <th>Submitted By</th>
          <th>Notes</th>
          <th class="right">Cash Amount</th>
          <th class="center">Locked</th>
          <th class="right">Adjustments</th>
          <th class="right">Adjusted Net</th>
        </tr>
      </thead>
      <tbody>
        @foreach ($typeEntries as $entry)
          @php $adjSum = $entry->adjustments->sum('adjusted_amount'); @endphp
          <tr>
            <td>{{ \Carbon\Carbon::parse($entry->entry_date)->format('d M Y') }}</td>
            <td>{{ $entry->user->name ?? '—' }}</td>
            <td class="text-muted">{{ $entry->notes ?? '—' }}</td>
            <td class="amount right">{{ number_format($entry->cash_amount, 2) }}</td>
            <td class="center">{{ $entry->is_locked ? 'Yes' : 'No' }}</td>
            <td class="amount right {{ $adjSum != 0 ? ($adjSum > 0 ? 'badge-in' : 'badge-out') : '' }}">
              {{ $adjSum != 0 ? number_format($adjSum, 2) : '—' }}
            </td>
            <td class="amount right">{{ number_format($entry->cash_amount + $adjSum, 2) }}</td>
          </tr>
          @foreach ($entry->adjustments as $adj)
            <tr style="background:#fef9c3 !important;">
              <td colspan="2" class="text-muted" style="padding-left:20px;">
                &rarr; Adjustment by {{ $adj->admin->name ?? '—' }}
                on {{ $adj->created_at->format('d M Y H:i') }}
              </td>
              <td colspan="2" class="text-muted">{{ $adj->reason }}</td>
              <td></td>
              <td class="amount right">{{ number_format($adj->adjusted_amount, 2) }}</td>
              <td></td>
            </tr>
          @endforeach
        @endforeach
        <tr class="subtotals-row">
          <td colspan="3"><strong>{{ $typeLabel }} Subtotal</strong></td>
          <td class="amount right">{{ number_format($typeEntries->sum('cash_amount'), 2) }}</td>
          <td></td>
          <td class="amount right">{{ number_format($typeEntries->flatMap->adjustments->sum('adjusted_amount'), 2) }}</td>
          <td class="amount right">{{ number_format($typeEntries->sum('cash_amount') + $typeEntries->flatMap->adjustments->sum('adjusted_amount'), 2) }}</td>
        </tr>
      </tbody>
    </table>
  @endforeach
  <table style="width:auto; margin: 4px 0 8px auto;">
    <tr>
      <th>Cash Total</th>
      <th>Cash Adj Total</th>
      <th>Cash Net Total</th>
    </tr>
    <tr class="subtotals-row">
      <td class="amount right">{{ number_format($cashTotal, 2) }}</td>
      <td class="amount right">{{ number_format($cashAdjTotal, 2) }}</td>
      <td class="amount right">{{ number_format($cashTotal + $cashAdjTotal, 2) }}</td>
    </tr>
  </table>
@endif

{{-- ── Card Entries ─────────────────────────────────────── --}}
<div class="section-title" style="margin-top:18px;">Daily Card Entries</div>

@if ($cardEntries->isEmpty())
  <div class="no-data">No card entries for this period.</div>
@else
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Submitted By</th>
        <th>Card Account</th>
        <th>Notes</th>
        <th class="right">Amount</th>
        <th class="center">Locked</th>
        <th class="right">Adjustments</th>
        <th class="right">Adjusted Net</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($cardEntries as $entry)
        @php $adjSum = $entry->adjustments->sum('adjusted_amount'); @endphp
        <tr>
          <td>{{ \Carbon\Carbon::parse($entry->entry_date)->format('d M Y') }}</td>
          <td>{{ $entry->user->name ?? '—' }}</td>
          <td>
            @if ($entry->cardAccount)
              {{ $entry->cardAccount->bank_name }}<br>
              <span class="text-muted">&bull;&bull;&bull;&bull; {{ $entry->cardAccount->last_four }}</span>
            @else
              —
            @endif
          </td>
          <td class="text-muted">{{ $entry->notes ?? '—' }}</td>
          <td class="amount right">{{ number_format($entry->amount, 2) }}</td>
          <td class="center">{{ $entry->is_locked ? 'Yes' : 'No' }}</td>
          <td class="amount right {{ $adjSum != 0 ? ($adjSum > 0 ? 'badge-in' : 'badge-out') : '' }}">
            {{ $adjSum != 0 ? number_format($adjSum, 2) : '—' }}
          </td>
          <td class="amount right">{{ number_format($entry->amount + $adjSum, 2) }}</td>
        </tr>
        @foreach ($entry->adjustments as $adj)
          <tr style="background:#fef9c3 !important;">
            <td colspan="3" class="text-muted" style="padding-left:20px;">
              &rarr; Adjustment by {{ $adj->admin->name ?? '—' }}
              on {{ $adj->created_at->format('d M Y H:i') }}
            </td>
            <td colspan="2" class="text-muted">{{ $adj->reason }}</td>
            <td></td>
            <td class="amount right">{{ number_format($adj->adjusted_amount, 2) }}</td>
            <td></td>
          </tr>
        @endforeach
      @endforeach
      <tr class="subtotals-row">
        <td colspan="4"><strong>Card Totals</strong></td>
        <td class="amount right">{{ number_format($cardTotal, 2) }}</td>
        <td></td>
        <td class="amount right">{{ number_format($cardAdjTotal, 2) }}</td>
        <td class="amount right">{{ number_format($cardTotal + $cardAdjTotal, 2) }}</td>
      </tr>
    </tbody>
  </table>
@endif

@endsection
