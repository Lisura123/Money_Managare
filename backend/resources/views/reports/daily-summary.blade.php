@extends('reports.layout')

@section('content')

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

{{-- Grand totals summary --}}
<table style="width:auto; margin-bottom:14px;">
  <tr>
    <th>Main Cash</th>
    <th>Mano's Cash</th>
    <th>Total Cash</th>
    <th>Total Card</th>
    <th>Grand Total</th>
  </tr>
  <tr class="">
    <td class="amount right" style="font-size:13px; font-weight:700; color:#065f46;">
      {{ number_format($grandMainCashTotal, 2) }}
    </td>
    <td class="amount right" style="font-size:13px; font-weight:700; color:#5b21b6;">
      {{ number_format($grandManoCashTotal, 2) }}
    </td>
    <td class="amount right" style="font-size:13px; font-weight:700; color:#065f46;">
      {{ number_format($grandCashTotal, 2) }}
    </td>
    <td class="amount right" style="font-size:13px; font-weight:700; color:#1e40af;">
      {{ number_format($grandCardTotal, 2) }}
    </td>
    <td class="amount right" style="font-size:13px; font-weight:700; color:#1e3a5f;">
      {{ number_format($grandCashTotal + $grandCardTotal, 2) }}
    </td>
  </tr>
</table>

@forelse ($showrooms as $showroom)
  <div class="section-title">
    {{ $showroom->name }} &nbsp;&mdash;&nbsp; {{ $showroom->location }}
  </div>

  {{-- Cash Entries by Account Type --}}
  <div class="subsection-title">Cash Entries</div>
  @if ($showroom->dailyCashEntries->isEmpty())
    <div class="no-data">No cash entries for this date.</div>
  @else
    @foreach ($showroom->cash_entries_by_type as $accountType => $typeEntries)
      @php $typeLabel = $accountType === 'mano' ? "Mano's Account" : 'Main Account'; @endphp
      <div style="font-size:10px; font-weight:700; color:{{ $accountType === 'mano' ? '#5b21b6' : '#065f46' }}; margin: 4px 0 2px; padding-left:4px;">
        {{ $typeLabel }}
      </div>
      <table>
        <thead>
          <tr>
            @unless ($isSingleDay)<th>Date</th>@endunless
            <th>Submitted By</th>
            <th>Notes</th>
            <th class="right">Cash Amount</th>
            <th class="center">Locked</th>
          </tr>
        </thead>
        <tbody>
          @foreach ($typeEntries as $entry)
          <tr>
            @unless ($isSingleDay)<td>{{ \Carbon\Carbon::parse($entry->entry_date)->format('d M Y') }}</td>@endunless
            <td>{{ $entry->user->name ?? '—' }}</td>
            <td class="text-muted">{{ $entry->notes ?? '—' }}</td>
            <td class="amount right">{{ number_format($entry->cash_amount, 2) }}</td>
            <td class="center">{{ $entry->is_locked ? 'Yes' : 'No' }}</td>
          </tr>
          @endforeach
          <tr class="subtotals-row">
            <td colspan="{{ $isSingleDay ? 2 : 3 }}"><strong>{{ $typeLabel }} Subtotal</strong></td>
            <td class="amount right">{{ number_format($typeEntries->sum('cash_amount'), 2) }}</td>
            <td></td>
          </tr>
        </tbody>
      </table>
    @endforeach
  @endif

  {{-- Card Entries by Account --}}
  <div class="subsection-title">Card Entries</div>
  @if ($showroom->dailyCardEntries->isEmpty())
    <div class="no-data">No card entries for this date.</div>
  @else
    @foreach ($showroom->card_entries_by_account as $group)
      @php $acct = $group['card_account']; @endphp
      <div style="font-size:10px; font-weight:700; color:#2c5282; margin: 4px 0 2px; padding-left:4px;">
        {{ $acct ? $acct->bank_name . ' &bull; &bull;&bull;&bull;&bull; ' . $acct->last_four : 'Unknown Card' }}
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
            <td class="text-muted">{{ $entry->notes ?? '—' }}</td>
            <td class="amount right">{{ number_format($entry->amount, 2) }}</td>
          </tr>
          @endforeach
          <tr class="subtotals-row">
            <td colspan="{{ $isSingleDay ? 2 : 3 }}"><strong>Account Subtotal</strong></td>
            <td class="amount right">{{ number_format($group['total'], 2) }}</td>
          </tr>
        </tbody>
      </table>
    @endforeach
  @endif

  {{-- Showroom row totals --}}
  <table style="width:auto; margin: 6px 0 12px auto;">
    <tr>
      <th>Main Cash</th>
      <th>Mano's Cash</th>
      <th>Total Cash</th>
      <th>Total Card</th>
      <th>Grand Total</th>
    </tr>
    <tr class="totals-row">
      <td class="amount right">{{ number_format($showroom->main_cash_total, 2) }}</td>
      <td class="amount right">{{ number_format($showroom->mano_cash_total, 2) }}</td>
      <td class="amount right">{{ number_format($showroom->cash_total, 2) }}</td>
      <td class="amount right">{{ number_format($showroom->card_total, 2) }}</td>
      <td class="amount right">{{ number_format($showroom->cash_total + $showroom->card_total, 2) }}</td>
    </tr>
  </table>

  @if (!$loop->last)
    <div class="page-break"></div>
  @endif

@empty
  <div class="no-data">No showrooms found.</div>
@endforelse

@endsection
