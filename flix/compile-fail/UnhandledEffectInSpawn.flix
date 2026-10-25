eff Client { def request(): String }

// Flix 0.79.0: Illegal spawn effect: 'Client'. A spawn expression must be
// pure or have a primitive effect. This file is intentionally outside src/.
def rejected(): Unit \ IO = region rc {
    spawn Client.request() @ rc
}

