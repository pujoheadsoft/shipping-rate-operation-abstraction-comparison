import java.util.concurrent.{CountDownLatch => JCountDownLatch}
import java.util.concurrent.{TimeUnit => JTimeUnit}
import java.util.concurrent.atomic.{AtomicBoolean => JAtomicBoolean}

def gateX(
    started: JCountDownLatch,
    release: JCountDownLatch,
    _: CarrierXRateRequest
): Result[CarrierXApiError, CarrierXRateResponse] \ IO = {
    started.countDown();
    discard release.await(5i64, JTimeUnit.SECONDS);
    Ok(CarrierXRateResponse.CarrierXRateResponse(1, "EXPRESS"))
}

def gateY(
    started: JCountDownLatch,
    release: JCountDownLatch,
    _: CarrierYRateRequest
): Result[CarrierYApiError, CarrierYRateResponse] \ IO = {
    started.countDown();
    discard release.await(5i64, JTimeUnit.SECONDS);
    Ok(CarrierYRateResponse.CarrierYRateResponse(2, "Standard Delivery"))
}

def gateZ(
    started: JCountDownLatch,
    release: JCountDownLatch,
    _: CarrierZRateRequest
): Result[CarrierZApiError, CarrierZRateResponse] \ IO = {
    started.countDown();
    discard release.await(5i64, JTimeUnit.SECONDS);
    Ok(CarrierZRateResponse.CarrierZRateResponse(3, "ECONOMY"))
}

@Test
def gatewayConcurrencyTest(): Unit \ {Assert, Chan, NonDet, IO} =
    let started = new JCountDownLatch(3);
    let release = new JCountDownLatch(1);
    let overlapped = new JAtomicBoolean(false);
    region rc {
        spawn {
            overlapped.set(started.await(5i64, JTimeUnit.SECONDS));
            release.countDown()
        } @ rc;
        let result = fetchShippingRates(
            Shipment.Shipment("111-1111", 1000),
            gateX(started, release),
            gateY(started, release),
            gateZ(started, release)
        );
        Assert.assertEq(
            expected = Ok(ShippingRates.ShippingRates(
                ShippingRate.ShippingRate("CarrierX", 1),
                ShippingRate.ShippingRate("CarrierY", 2) ::
                    ShippingRate.ShippingRate("CarrierZ", 3) :: Nil
            )),
            result
        );
        Assert.assertEq(expected = true, overlapped.get())
    }
