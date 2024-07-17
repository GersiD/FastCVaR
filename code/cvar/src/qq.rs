use std::f64;

fn ess_inf(vals: &[f64], p: &[f64]) -> f64 {
    let mut ess_inf = f64::MAX;
    for (i, v) in vals.iter().enumerate() {
        if p[i] > 0.0 {
            ess_inf = ess_inf.min(*v);
        }
    }
    ess_inf
}

fn swap(vals: &mut [f64], p: &mut [f64], i: usize, j: usize) {
    vals.swap(i, j);
    p.swap(i, j);
}

fn partition(vals: &mut [f64], p: &mut [f64], i: usize, j: usize) -> usize {
    let pivot = (i + j) / 2;
    let pivot_val = vals[pivot];
    swap(vals, p, pivot, j);
    let mut store_index = i;
    for k in i..=j {
        if vals[k] < pivot_val {
            swap(vals, p, store_index, k);
            store_index += 1;
        }
    }
    swap(vals, p, j, store_index);
    store_index
}

pub fn qql(vals: &mut [f64], p: &mut [f64], alpha: f64) -> f64 {
    if alpha == 0.0 {
        return ess_inf(vals, p);
    } else if alpha == 1.0 {
        return f64::MAX;
    }
    let mut i = 0;
    let mut j = vals.len() - 1;
    while j - i >= 1 {
        let k = partition(vals, p, i, j);
        // tail is the sum of the probabilities of the elements which are less than vals[k]
        let tail: f64 = p[0..=k].iter().sum();
        if alpha < tail {
            j = k;
        } else {
            i = k + 1;
        }
    }
    vals[i]
}

pub fn cvar(vals: &mut [f64], p: &mut [f64], alpha: f64) -> f64 {
    if alpha == 0.0 {
        return ess_inf(vals, p);
    } else if alpha == 1.0 {
        // Expectation
        return vals.iter().zip(p.iter()).map(|(v, p)| *v * *p).sum();
    }
    let q = qql(vals, p, alpha);

    let mut value = 0.0;
    let mut p_left = 1.0;
    let alpha_hat = alpha;
    for (i, vs) in vals.iter().enumerate() {
        if *vs <= q {
            let increment = (p[i] / alpha_hat).min(p_left);
            value += increment * *vs;
            p_left -= increment;
            if p_left <= 0.0 {
                break;
            }
        }
    }
    value
}

pub fn slow_cvar(vals: &[f64], p: &[f64], alpha: f64) -> f64 {
    if alpha == 0.0 {
        return ess_inf(vals, p);
    } else if alpha == 1.0 {
        return vals.iter().zip(p.iter()).map(|(v, p)| *v * *p).sum();
    }
    let mut value = 0.0;
    let mut p_left = 1.0;
    let alpha_hat = alpha;
    let sorted_i = &mut [(0..vals.len()).collect::<Vec<usize>>()][0];
    sorted_i.sort_by(|a, b| vals[*a].partial_cmp(&vals[*b]).unwrap());
    for i in sorted_i.iter() {
        let increment: f64 = (p[*i] / alpha_hat).min(p_left);
        value += increment * vals[*i];
        p_left -= increment;
        if p_left <= 0.0 {
            break;
        }
    }
    value
}
