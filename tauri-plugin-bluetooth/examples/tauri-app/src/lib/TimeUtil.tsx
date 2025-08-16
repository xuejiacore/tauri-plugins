function padZero(num: number): string {
    return num.toString().padStart(2, '0'); // 使用 padStart 方法在数字前面填充 0，以确保始终为两位数
}

export function formatTimestamp(timestamp: number, format: string = 'YYYY-MM-DD HH:mm:ss', engMon: boolean = false): string {
    const date = new Date(timestamp); // JavaScript 时间戳是以毫秒为单位的，所以需要乘以 1000

    const year = date.getFullYear();
    const month = padZero(date.getMonth() + 1); // 月份是从 0 开始的，所以需要加 1
    const day = padZero(date.getDate());
    const hours = padZero(date.getHours());
    const minutes = padZero(date.getMinutes());
    const seconds = padZero(date.getSeconds());

    return format
        .replace('YYYY', year.toString())
        .replace('MM', engMon ? formatMonth(parseInt(month)) ?? month : month)
        .replace('DD', day)
        .replace('HH', hours)
        .replace('mm', minutes)
        .replace('ss', seconds);
}

export function formatMonth(month: number) {
    switch (month) {
        case 1:
            return "Jan";
        case 2:
            return "Feb";
        case 3:
            return "Mar";
        case 4:
            return "Apr";
        case 5:
            return "May";
        case 6:
            return "Jun";
        case 7:
            return "Jul";
        case 8:
            return "Aug";
        case 9:
            return "Sep";
        case 10:
            return "Oct";
        case 11:
            return "Nov";
        case 12:
            return "Dec";
    }
}

export function timeUntil(timestamp: number): string {
    const now = Date.now(); // 当前时间的时间戳
    const diff = timestamp - now; // 计算时间差

    const msInSecond = 1000;
    const msInMinute = msInSecond * 60;
    const msInHour = msInMinute * 60;
    const msInDay = msInHour * 24;
    const msInMonth = msInDay * 30;
    const msInYear = msInDay * 365;

    const symbol = diff > 0 ? '+' : '-';
    const absDiff = Math.abs(diff);
    if (absDiff > msInYear) {
        return `${symbol}${Math.floor(absDiff / msInYear)}year`;
    } else if (absDiff > msInMonth) {
        return `${symbol}${Math.floor(absDiff / msInMonth)}mon`;
    } else if (absDiff > msInDay) {
        return `${symbol}${Math.floor(absDiff / msInDay)}day`;
    } else if (absDiff > msInHour) {
        return `${symbol}${Math.floor(absDiff / msInHour)}hour`;
    } else if (absDiff > msInMinute) {
        return `${symbol}${Math.floor(absDiff / msInMinute)}min`;
    } else if (absDiff > msInSecond) {
        return `${symbol}${Math.floor(absDiff / msInSecond)}sec`;
    } else {
        return '';
    }
}

export function convertTimestampToDateWithMillis(timestamp: any): string {
    const ts = timestamp.toString();
    if (!parseInt(ts)) {
        return timestamp;
    }

    const numLen = ts.length;
    if (numLen !== 10 && numLen !== 13) {
        return timestamp;
    }

    let timestampNum = parseInt(timestamp);
    // 如果时间戳是 10 位，认为是秒时间戳，乘以 1000 转换为毫秒
    if (numLen === 10) {
        timestampNum *= 1000;
    }

    // 将时间戳转换为 Date 对象
    const date = new Date(timestampNum);

    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0'); // 月份从0开始
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    const milliseconds = date.getMilliseconds().toString().padStart(3, '0');

    // 拼接成所需格式: 年-月-日 时:分:秒.毫秒
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}\n${timeUntil(timestampNum)}`;
}

