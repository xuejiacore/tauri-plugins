#ifdef __cplusplus
extern "C" {
#endif
typedef void (*IapCallback)(const char* callback);

const char* native_purchase(const char* accountToken, const char* productId);

void native_restore_purchase();

void native_register_iap_callback(IapCallback callback);

#ifdef __cplusplus
}
#endif
