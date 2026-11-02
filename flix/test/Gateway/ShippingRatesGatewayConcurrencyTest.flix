import java.util.concurrent.{CountDownLatch => JCountDownLatch}
import java.util.concurrent.{TimeUnit => JTimeUnit}
import java.util.concurrent.atomic.{AtomicBoolean => JAtomicBoolean}

use Domain.PostalCode
use Domain.Weight
use Domain.Shipment
use Domain.ShippingRate
use Domain.ShippingRates
use Gateway.CarrierXApiClient.{CarrierXApiClient, CarrierXApiError, CarrierXRateRequest, CarrierXRateResponse}
use Gateway.CarrierYApiClient.{CarrierYApiClient, CarrierYApiError, CarrierYRateRequest, CarrierYRateResponse}
use Gateway.CarrierZApiClient.{CarrierZApiClient, CarrierZApiError, CarrierZRateRequest, CarrierZRateResponse}
use Gateway.ShippingRatesGateway.{fetchShippingRatesConcurrently, fetchX, fetchY, fetchZ}

def runConcurrencyTestX(
    clientHandler: CarrierXRateRequest -> Result[CarrierXApiError, CarrierXRateResponse] \ IO,
    action: Unit -> a \ CarrierXApiClient
): a \ IO = run { action() } with handler CarrierXApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

def runConcurrencyTestY(
    clientHandler: CarrierYRateRequest -> Result[CarrierYApiError, CarrierYRateResponse] \ IO,
    action: Unit -> a \ CarrierYApiClient
): a \ IO = run { action() } with handler CarrierYApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

def runConcurrencyTestZ(
    clientHandler: CarrierZRateRequest -> Result[CarrierZApiError, CarrierZRateResponse] \ IO,
    action: Unit -> a \ CarrierZApiClient
): a \ IO = run { action() } with handler CarrierZApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

def gateX(
    started: JCountDownLatch,
    release: JCountDownLatch,
    _: CarrierXRateRequest
): Result[CarrierXApiError, CarrierXRateResponse] \ IO = {
    started.countDown();
    discard release.await(5i64, JTimeUnit.SECONDS);
    Ok(CarrierXRateResponse.CarrierXRateResponse({ amount = 1, serviceCode = "EXPRESS" }))
}

def gateY(
    started: JCountDownLatch,
    release: JCountDownLatch,
    _: CarrierYRateRequest
): Result[CarrierYApiError, CarrierYRateResponse] \ IO = {
    started.countDown();
    discard release.await(5i64, JTimeUnit.SECONDS);
    Ok(CarrierYRateResponse.CarrierYRateResponse({ price = 2, serviceName = "Standard Delivery" }))
}

def gateZ(
    started: JCountDownLatch,
    release: JCountDownLatch,
    _: CarrierZRateRequest
): Result[CarrierZApiError, CarrierZRateResponse] \ IO = {
    started.countDown();
    discard release.await(5i64, JTimeUnit.SECONDS);
    Ok(CarrierZRateResponse.CarrierZRateResponse({ amount = 3, serviceCode = "ECONOMY" }))
}

@Test
def gatewayConcurrencyTest(): Unit \ {Assert, Chan, NonDet, IO} =
    let started = new JCountDownLatch(3);
    let release = new JCountDownLatch(1);
    let overlapped = new JAtomicBoolean(false);
    let shipment = Shipment({
        destinationPostalCode = PostalCode("111-1111"),
        weight = Weight(1000)
    });
    region rc {
        spawn {
            overlapped.set(started.await(5i64, JTimeUnit.SECONDS));
            release.countDown()
        } @ rc;
        let result = fetchShippingRatesConcurrently(
            () -> runConcurrencyTestX(gateX(started, release), () -> fetchX(shipment)),
            () -> runConcurrencyTestY(gateY(started, release), () -> fetchY(shipment)),
            () -> runConcurrencyTestZ(gateZ(started, release), () -> fetchZ(shipment))
        );
        Assert.assertEq(
            expected = Ok(ShippingRates(
                ShippingRate({ carrier = "CarrierX", amount = 1 }),
                ShippingRate({ carrier = "CarrierY", amount = 2 }) ::
                    ShippingRate({ carrier = "CarrierZ", amount = 3 }) :: Nil
            )),
            result
        );
        Assert.assertEq(expected = true, overlapped.get())
    }
