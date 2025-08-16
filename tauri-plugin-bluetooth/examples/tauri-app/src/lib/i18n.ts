import i18n from "i18next";
import {initReactI18next} from "react-i18next";

import enTranslation from "../assets/locales/en/translation.json"
import zhTranslation from "../assets/locales/zh/translation.json"

export const defaultLanguage = navigator.language;
// export const defaultLanguage = 'zh-CN';
i18n
    .use(initReactI18next)
    .init({
        resources: {
            'en-US': {
                translation: enTranslation
            },
            'zh': {
                translation: zhTranslation
            }
        },
        lng: defaultLanguage,
        fallbackLng: "en-US",
        interpolation: {
            escapeValue: false
        }
    });

export default i18n;