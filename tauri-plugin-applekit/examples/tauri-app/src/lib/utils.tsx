import {useEffect, useState} from 'react';

export function humanByteSize(bytes: number, decimals: number = 2) {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals; // 确保小数点的位数
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

export function getTextWidth(text: string, font: string) {
    const span = document.createElement('span');
    span.style.font = font; // 设置字体样式
    span.style.position = 'absolute'; // 隐藏元素
    span.style.visibility = 'hidden';
    span.style.whiteSpace = 'nowrap'; // 防止换行
    span.innerText = text;
    document.body.appendChild(span);
    const width = span.offsetWidth;
    document.body.removeChild(span); // 移除元素
    return width;
}

export function useDevicePixelRatio() {
    const [dpr, setDpr] = useState(window.devicePixelRatio);

    useEffect(() => {
        const updateDpr = () => {
            setDpr(window.devicePixelRatio);
        };

        // 监听窗口缩放事件
        window.addEventListener('resize', updateDpr);

        // 使用 matchMedia 监听 DPR 变化（更精确）
        const mediaMatcher = window.matchMedia(`(resolution: ${window.devicePixelRatio}dppx)`);
        mediaMatcher.addEventListener('change', updateDpr);

        return () => {
            window.removeEventListener('resize', updateDpr);
            mediaMatcher.removeEventListener('change', updateDpr);
        };
    }, []);

    return dpr;
}
