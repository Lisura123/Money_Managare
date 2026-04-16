@extends('reports.layout')

@section('content')

<div class="report-header">
  <div class="brand">Money Manager &mdash; Admin Report</div>
  <h1>Card Account Statement</h1>
  <div class="meta">
    <span>Card: <strong>{{ $cardAccount->bank_name }} &bull; &bull;&bull;&bull;&bull; {{ $cardAccount->last_four }}</strong></span>
    <span>Showroom: <strong>{{ $cardAccount->showroom->name ?? '—' }}</strong></span>
    <span>Period: <strong>{{ \Carbon\Carbon::parse($from)->format('d M Y') }}</strong>
      &ndash; <strong>{{ \Carbon\Carbon::parse($to)->format('d M Y') }}</strong></span>
  </div>
</div>

{{-- Summary --}}
<table style="width:auto; margin-bottom:16px;">
  <tr>
    <th>Card Entries</th>
    <th>Adjustments</th>
    <th>Transfers Out</th>
    <th>Transfers In</th>
    <th>Net Movement</th>
    <th>Current Balance</th>
  </tr>
  <tr class="totals-row">
    <td class="amount right badge-in" style="color:#a3e635;">+{{ number_format($entryTotal, 2) }}</td>
    <td class="amount right" style="{{ $adjTotal >= 0 ? 'color:#a3e635;' : 'color:#fca5a5;' }}">
      {{ $adjTotal >= 0 ? '+' : '' }}{{ number_format($adjTotal, 2) }}
    </td>
    <td class="amount right" style="color:#fca5a5;">-{{ number_format($txOutTotal, 2) }}</td>
    <td class="amount right" style="color:#a3e635;">+{{ number_format($txInTotal, 2) }}</td>
    <td class="amount right">{{ number_format($netMovement, 2) }}</td>
    <td class="amount right">{{ number_format($cardAccount->current_balance, 2) }}</td>
  </tr>
</table>

{{-- ── Card Entries ─────────────────────────────────────── --}}
<div class="section-title">Card Entries</div>

@if ($cardEntries->isEmpty())
  <div class="no-data">No card entries in this period.</div>
@else
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Submitted By</th>
        <th>Notes</th>
        <th class="right">Amount</th>
        <th class="center">Locked</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($cardEntries as $entry)
      <tr>
        <td>{{ \Carbon\Carbon::parse($entry->entry_date)->format('d M Y') }}</td>
        <td>{{ $entry->user->name ?? '—' }}</td>
        <td class="text-muted">{{ $entry->notes ?? '—' }}</td>
        <td class="amount right badge-in">+{{ number_format($entry->amount, 2) }}</td>
        <td class="center">{{ $entry->is_locked ? 'Yes' : 'No' }}</td>
      </tr>
      @endforeach
      <tr class="subtotals-row">
        <td colspan="3"><strong>Entries Total</strong></td>
        <td class="amount right">+{{ number_format($entryTotal, 2) }}</td>
        <td></td>
      </tr>
    </tbody>
  </table>
@endif

{{-- ── Adjustments ──────────────────────────────────────── --}}
<div class="section-title" style="margin-top:16px;">Admin Adjustments</div>

@if ($adjustments->isEmpty())
  <div class="no-data">No adjustments in this period.</div>
@else
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Entry Date</th>
        <th>Admin</th>
        <th>Reason</th>
        <th class="right">Adjusted Amount</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($adjustments as $adj)
      <tr>
        <td>{{ $adj->created_at->format('d M Y H:i') }}</td>
        <td>{{ $adj->dailyCardEntry ? \Carbon\Carbon::parse($adj->dailyCardEntry->entry_date)->format('d M Y') : '—' }}</td>
        <td>{{ $adj->admin->name ?? '—' }}</td>
        <td class="text-muted">{{ $adj->reason }}</td>
        <td class="amount right {{ $adj->adjusted_amount >= 0 ? 'badge-in' : 'badge-out' }}">
          {{ $adj->adjusted_amount >= 0 ? '+' : '' }}{{ number_format($adj->adjusted_amount, 2) }}
        </td>
      </tr>
      @endforeach
      <tr class="subtotals-row">
        <td colspan="4"><strong>Adjustments Total</strong></td>
        <td class="amount right">{{ $adjTotal >= 0 ? '+' : '' }}{{ number_format($adjTotal, 2) }}</td>
      </tr>
    </tbody>
  </table>
@endif

{{-- ── Outgoing Self-Transactions ───────────────────────── --}}
<div class="section-title" style="margin-top:16px;">Transfers Out</div>

@if ($selfTxOut->isEmpty())
  <div class="no-data">No outgoing transfers in this period.</div>
@else
  <table>
    <thead>
      <tr>
        <th>Date &amp; Time</th>
        <th>To Card (Showroom)</th>
        <th>Admin</th>
        <th>Notes</th>
        <th class="right">Amount</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($selfTxOut as $tx)
      <tr>
        <td>{{ $tx->created_at->format('d M Y H:i') }}</td>
        <td>
          {{ $tx->toCardAccount->showroom->name ?? '—' }}<br>
          <span class="text-muted">{{ $tx->toCardAccount->bank_name ?? '' }}
            &bull;&bull;&bull;&bull; {{ $tx->toCardAccount->last_four ?? '' }}</span>
        </td>
        <td>{{ $tx->admin->name ?? '—' }}</td>
        <td class="text-muted">{{ $tx->notes ?? '—' }}</td>
        <td class="amount right badge-out">-{{ number_format($tx->amount, 2) }}</td>
      </tr>
      @endforeach
      <tr class="subtotals-row">
        <td colspan="4"><strong>Transfers Out Total</strong></td>
        <td class="amount right badge-out">-{{ number_format($txOutTotal, 2) }}</td>
      </tr>
    </tbody>
  </table>
@endif

{{-- ── Incoming Self-Transactions ───────────────────────── --}}
<div class="section-title" style="margin-top:16px;">Transfers In</div>

@if ($selfTxIn->isEmpty())
  <div class="no-data">No incoming transfers in this period.</div>
@else
  <table>
    <thead>
      <tr>
        <th>Date &amp; Time</th>
        <th>From Card (Showroom)</th>
        <th>Admin</th>
        <th>Notes</th>
        <th class="right">Amount</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($selfTxIn as $tx)
      <tr>
        <td>{{ $tx->created_at->format('d M Y H:i') }}</td>
        <td>
          {{ $tx->fromCardAccount->showroom->name ?? '—' }}<br>
          <span class="text-muted">{{ $tx->fromCardAccount->bank_name ?? '' }}
            &bull;&bull;&bull;&bull; {{ $tx->fromCardAccount->last_four ?? '' }}</span>
        </td>
        <td>{{ $tx->admin->name ?? '—' }}</td>
        <td class="text-muted">{{ $tx->notes ?? '—' }}</td>
        <td class="amount right badge-in">+{{ number_format($tx->amount, 2) }}</td>
      </tr>
      @endforeach
      <tr class="subtotals-row">
        <td colspan="4"><strong>Transfers In Total</strong></td>
        <td class="amount right badge-in">+{{ number_format($txInTotal, 2) }}</td>
      </tr>
    </tbody>
  </table>
@endif

@endsection
