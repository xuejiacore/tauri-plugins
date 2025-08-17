#ifdef __cplusplus
extern "C" {
#endif

// echo for test
const char* echo(const char* echo);

// connect the bluetooth adapter
bool connect();

void set_delegate();

#ifdef __cplusplus
}
#endif
