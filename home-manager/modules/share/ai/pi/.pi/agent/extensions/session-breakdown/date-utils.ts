export function toLocalDayKey(d: Date): string {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

export function localMidnight(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
}

export function addDaysLocal(d: Date, days: number): Date {
  const x = new Date(d);
  x.setDate(x.getDate() + days);
  return x;
}

export function countDaysInclusiveLocal(start: Date, end: Date): number {
  // Avoid ms-based day math because DST transitions can make a "day" 23/25h in local time.
  let n = 0;
  for (let d = new Date(start); d <= end; d = addDaysLocal(d, 1)) n++;
  return n;
}

export function mondayIndex(date: Date): number {
  // Mon=0 .. Sun=6
  return (date.getDay() + 6) % 7;
}
